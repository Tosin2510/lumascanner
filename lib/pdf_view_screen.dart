import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumascanner/camera_screen.dart';
import 'package:lumascanner/edit_text_screen.dart';
import 'package:lumascanner/extracted_text_screen.dart';
import 'package:lumascanner/services/export_service.dart';
import 'package:lumascanner/services/image_enhancement_service.dart';
import 'package:lumascanner/services/ocr_service.dart';
import 'package:path/path.dart' as path;
import 'package:printing/printing.dart';

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
  late String currentNameOfPdf;
  final enhancementService = ImageEnhancementService();

  @override
  void initState() {
    super.initState();
    currentpathOfPdf = widget.pdfPath;
    currentNameOfPdf = path.basenameWithoutExtension(currentpathOfPdf);
  }

  @override
  void dispose() {
    ocrService.dispose();
    super.dispose();
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
        )
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
      body: PdfPreview(
        key: ValueKey(currentpathOfPdf),
        build: (format) => File(currentpathOfPdf).readAsBytes(),
        useActions: false,
        scrollViewDecoration: const BoxDecoration(color: Colors.black),
        previewPageMargin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        canChangePageFormat: false,
        canChangeOrientation: false,
        loadingWidget: const Center(child: CircularProgressIndicator(color: Colors.white)),
        allowPrinting: true,
        allowSharing: false,
        pdfPreviewPageDecoration: const BoxDecoration(),
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

            IconButton(
              icon: const Icon(Icons.edit_document, color: Colors.white),
              tooltip: 'Edit Text',
              onPressed: editText,
            ),
          ]
        )
      )
    );
  }

  final ocrService = OCRService();

  Future<void> editText() async {
    if (widget.pages.length == 1) {
        final result = await ocrService.processImage(widget.pages[0].path);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditTextScreen(page: widget.pages[0], pageResult: result),
          ),
        );
        return;
    }

    final selectedPageIndex = await showModalBottomSheet<int>(
    context: context,
    backgroundColor: const Color(0xFF0D1118),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int val = 0; val < widget.pages.length; val++)
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(File(widget.pages[val].path), width: 40, height: 50, fit: BoxFit.cover),
              ),
              title: Text('Page ${val + 1}', style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, val),
            ),
        ],
      ),
    ),
  );

  if (selectedPageIndex == null || !mounted) return;
  final result = await ocrService.processImage(widget.pages[selectedPageIndex].path);
  if (!mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditTextScreen(page: widget.pages[selectedPageIndex], pageResult: result),
    ),
  );

  }

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
}