import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker/image_picker.dart';
import 'package:lumascanner/camera_screen.dart';
import 'package:lumascanner/extracted_text_screen.dart';
import 'package:lumascanner/services/export_service.dart';
import 'package:lumascanner/services/image_enhancement_service.dart';
import 'package:lumascanner/services/ocr_service.dart';
import 'package:path/path.dart' as path;

class PdfViewScreen extends StatefulWidget {
  final String pdfPath;
  final List<XFile> pages;

  const PdfViewScreen({
    super.key,
    required this.pdfPath,
    required this.pages
  });
  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {

  final ExportService exportService = ExportService();
  late String currentpathOfPdf;
  List<List<TextElement>> wordsPerPage = [];
  late String currentNameOfPdf;
  final enhancementService = ImageEnhancementService();
  Offset? dragStart;
  bool isLoadingPages = true;
  List<Size?> pixelSizePerPage = [];
  final Map<TextElement, String> updatedText = {};

  int? activePageIndex;

  Offset? dragCurrent;

  List<TextElement> highlightedWords = [];

  @override
  void initState() {
    super.initState();
    currentpathOfPdf = widget.pdfPath;
    currentNameOfPdf = path.basenameWithoutExtension(currentpathOfPdf);
    loadAllPages();
  }

  @override
  void dispose() {
    ocrService.dispose();
    super.dispose();
  }

  String get highlightedText {

    final buffer = StringBuffer();
    for (int val = 0; val < highlightedWords.length; val++) {
      final word = highlightedWords[val];
      buffer.write(updatedText[word] ?? word.text);
      if (val != highlightedWords.length - 1) buffer.write(' ');
    }
    return buffer.toString();
  }


  Future<void> loadAllPages() async {

    final sizesVal = <Size?>[];
    final wordsVal = <List<TextElement>>[];

    for (final page in widget.pages) {
      final byteVal = await File(page.path).readAsBytes();
      final decodedImage = image.decodeImage(byteVal)!;

      final recognizedImg = await ocrService.processImage(page.path);
      final wordsForPage = <TextElement>[];
      for (final block in recognizedImg.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            wordsForPage.add(element);
          }
        }
      }

      sizesVal.add(Size(decodedImage.width.toDouble(), decodedImage.height.toDouble()));
      wordsVal.add(wordsForPage);
    }

    if (!mounted) return;
    setState(() {
      pixelSizePerPage = sizesVal;
      wordsPerPage = wordsVal;
      isLoadingPages = false;
    });
  }

  void startTextHighlight(Offset textPosition, int pageIndex) {
    setState(() {
      activePageIndex = pageIndex;
      dragStart = textPosition;
      dragCurrent = textPosition;
      highlightedWords = [];
    });
  }

  void updateTextHighlight(Offset textPosition, Rect display, double scaleX, double scaleY, int pageIndex) {
    final selectionRect = Rect.fromPoints(dragStart!, textPosition);
    final hits = <TextElement>[];
    for (final word in wordsPerPage[pageIndex]) {
      final wordRect = Rect.fromLTWH(
        display.left + word.boundingBox.left * scaleX,
        display.top + word.boundingBox.top * scaleY,
        word.boundingBox.width * scaleX,
        word.boundingBox.height * scaleY,
      );
      if (selectionRect.overlaps(wordRect)) hits.add(word);
    }

    setState(() {
      dragCurrent = textPosition;
      highlightedWords = hits;
    });
  }

  void endTextHighlight() {
    setState(() {
      dragStart = null;
      dragCurrent = null;
    });
  }

  void cancelHighlightedText() {
    setState(() {
      activePageIndex = null;
      highlightedWords = [];
    });
  }
  
  void copyHighlightedText() {
    Clipboard.setData(ClipboardData(text: highlightedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied')),
    );
    cancelHighlightedText();
  }

  void deleteHighlightedText() {
    setState(() {
      for (final word in highlightedWords) {
        updatedText[word] = '';
      }
    });
    cancelHighlightedText();
  }

  Future<void> addExtraPages() async {
    final decision = await showModalBottomSheet(
      context: context, 
      backgroundColor: const Color(0xFF0D1118),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop('camera'),
            ),

            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Select from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).pop('gallery'),
            )
          ]

        )
      )
    );

    if (!mounted) return;
    
    List<XFile>? newPickedImages;
    if (decision == 'gallery') {
      final imagePicker = ImagePicker();
      final additionalImages = await imagePicker.pickMultiImage();
      if (additionalImages.isNotEmpty) {
        newPickedImages = additionalImages;
      }
    } else if (decision == 'camera') {
      final value = await Navigator.push<List<XFile>>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(returnPreviewPages: true),
        ),
      );
      if (value != null && value.isNotEmpty) {
        newPickedImages = value;
      }

      if (!mounted || newPickedImages == null) return;

      final enhancedAddedPages = <XFile>[];
      for (final page in newPickedImages) {
        final enhancedImagePath = await enhancementService.autoEnhance(page.path);
        enhancedAddedPages.add(XFile(enhancedImagePath));
      }

      if (!mounted) return;
      editPages(extraPages: enhancedAddedPages);
    }
  }

  Rect displayRect(Size boxSize, Size imageSize) {
    final boxAspectRatio = boxSize.width / boxSize.height;
    final imageAspectRatio = imageSize.width / imageSize.height;

    double width;
    double height;

    if (imageAspectRatio > boxAspectRatio) {
      width = boxSize.width;
      height = boxSize.width / imageAspectRatio;
    } else {
      height = boxSize.height;
      width = boxSize.height * imageAspectRatio;
    }

    final xVal = (boxSize.width - width) / 2;
    final yVal = (boxSize.height - height) / 2;
    return Rect.fromLTWH(xVal, yVal, width, height);
  }
   void selectEverythingOnAPage(int pageIndex, Rect display, double scaleX, double scaleY) {
    setState(() {
      activePageIndex = pageIndex;
      highlightedWords = List.from(wordsPerPage[pageIndex]);
      dragStart = null;
      dragCurrent = null;
    });
  }


  void editPages({List<XFile>? extraPages}) {
    final completePages = [...widget.pages, ...?extraPages];
    Navigator.pop(context, completePages);
  }

  Future<void> renameDocument() async {
    final TextEditingController controller = TextEditingController(text: currentNameOfPdf);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1118),
          title: const Text('Rename Document', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter document name',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save', style: TextStyle(color: Color(0xFF4A9EFF))),
            ),
          ]
        );
      }
    );
    if (newName != null && newName.isNotEmpty) {
      final directory = path.dirname(currentpathOfPdf);
      final newPath = path.join(directory, "$newName.pdf");
      final renamedFile = await File(currentpathOfPdf).rename(newPath);

      setState(() {
        currentpathOfPdf = renamedFile.path;
        currentNameOfPdf  = newName;
      });
    }
  }

  Widget buildItemInPage(int pageIndex) {
    final pixelOfImage = pixelSizePerPage[pageIndex];
    if (pixelOfImage == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final pageHeight = screenWidth * (pixelOfImage.height / pixelOfImage.width);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: screenWidth,
        height: pageHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sizeOfBox = Size(constraints.maxWidth, constraints.maxHeight);
            final display = displayRect(sizeOfBox, pixelOfImage);
            final scaleX = display.width / pixelOfImage.width;
            final scaleY = display.height / pixelOfImage.height;
            final isActivePage = activePageIndex == pageIndex;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPressStart: (details) => startTextHighlight(details.localPosition, pageIndex),
              onLongPressMoveUpdate: (details) =>
                  updateTextHighlight(details.localPosition, display, scaleX, scaleY, pageIndex),
              onLongPressEnd: (_) => endTextHighlight(),
              onTap: cancelHighlightedText,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(
                      File(widget.pages[pageIndex].path),
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (isActivePage)
                    for (final word in highlightedWords)
                      Positioned(
                        left: display.left + word.boundingBox.left * scaleX,
                        top: display.top + word.boundingBox.top * scaleY,
                        width: word.boundingBox.width * scaleX,
                        height: word.boundingBox.height * scaleY,
                        child: Container(
                          color: const Color(0xFF4A9EFF).withValues(alpha: 0.35),
                        ),
                      ),
                  if (isActivePage && dragStart != null && dragCurrent != null)
                    Positioned.fromRect(
                      rect: Rect.fromPoints(dragStart!, dragCurrent!),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF4A9EFF), width: 1),
                        ),
                      ),
                    ),
                  if (isActivePage && highlightedWords.isNotEmpty && dragStart == null)
                    Positioned(
                      left: display.left + highlightedWords.first.boundingBox.left * scaleX,
                      top: (display.top + highlightedWords.first.boundingBox.top * scaleY - 46)
                          .clamp(0, double.infinity),
                      child: Material(
                        color: const Color(0xFF0D1118),
                        borderRadius: BorderRadius.circular(10),
                        elevation: 6,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                              tooltip: 'Copy',
                              onPressed: copyHighlightedText,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                              tooltip: 'Delete',
                              onPressed: deleteHighlightedText,
                            ),
                            IconButton(
                              icon: const Icon(Icons.select_all, color: Colors.white, size: 18),
                              tooltip: 'Select All',
                              onPressed: () => selectEverythingOnAPage(pageIndex, display, scaleX, scaleY),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF4A9EFF), size: 18),
                              tooltip: 'Edit Text',
                              onPressed: openEditTextPart,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1118),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: InkWell(
          onTap: renameDocument,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  currentNameOfPdf,
                  overflow: TextOverflow.ellipsis,
                )
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit, size: 16)
            ],
          )
        ),
      ),
      
      body: isLoadingPages
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView.builder(
              itemCount: widget.pages.length,
              itemBuilder: (context, index) => buildItemInPage(index),
            ),
      
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF0D1118),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: 'Share',
              onPressed: () => exportService.shareDocument(currentpathOfPdf),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              tooltip: 'Add Page',
              onPressed: () => addExtraPages(),
            ),
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.white),
              tooltip: 'Edit',
              onPressed: () => editPages(),
            ),

            IconButton(
              icon: const Icon(Icons.text_fields, color: Colors.white),
              tooltip: 'Extract Text',
              onPressed: extractText,
            ),
          ]
        )
      )
    );
  }

  final ocrService = OCRService();

  Future<void> extractText() async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
  );

  final pageResults = <RecognizedText>[];
  for (final page in widget.pages) {
    final result = await ocrService.processImage(page.path);
    pageResults.add(result);
  }

  if (!mounted) return;
  Navigator.pop(context);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ExtractedTextScreen(
        pages: widget.pages,
        pageResults: pageResults,
      ),
    ),
  );
}

  void openEditTextPart() {
    if (highlightedWords.isEmpty) return;
    final controller = TextEditingController(text: highlightedText);

    showModalBottomSheet(
      context: context, 
      backgroundColor: const Color(0xFF0D1118),
      isScrollControlled: true,

      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Text',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: controller,
              maxLines: null,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF4A9EFF))),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                  TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),

                TextButton(
                  onPressed: () {
                    setState(() {
                      updatedText[highlightedWords.first] = controller.text;
                      for (int val = 1; val < highlightedWords.length; val++) {
                        updatedText[highlightedWords[val]] = '';
                      }
                    });
                    
                    Navigator.pop(context);
                    cancelHighlightedText();
                  },
                  child: const Text('Done', style: TextStyle(color: Color(0xFF4A9EFF))),
                ),
              ]
            )
          ],
        )    
      )
    );
  }
}