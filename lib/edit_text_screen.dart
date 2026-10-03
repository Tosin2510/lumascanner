import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as image;

class EditTextScreen extends StatefulWidget {
  final XFile page;
  final RecognizedText pageResult;

  const EditTextScreen({
    super.key,
    required this.page,
    required this.pageResult,
  });

  @override
  State<EditTextScreen> createState() => _EditTextScreenState();
}

class _EditTextScreenState extends State<EditTextScreen> {

  Size? pixelOfImage;
  Offset? position;
  List<TextBlock>? selectedValues;
  TextBlock? selectedTextPart;
  final Map<TextBlock, String> correctedText = {};

  @override
  void initState() {
    super.initState();
    loadImage();
  }

  Future<void> loadImage() async {
    final byteVal = await File(widget.page.path).readAsBytes();
    final decodedImage = image.decodeImage(byteVal)!;

    final sortedVal = List<TextBlock>.from(widget.pageResult.blocks)
    ..sort((firstVal, secondVal) {
        final topCompare = firstVal.boundingBox.top.compareTo(secondVal.boundingBox.top);
        if (topCompare != 0) return topCompare;
        return firstVal.boundingBox.left.compareTo(secondVal.boundingBox.left);
      });

      if (!mounted) return;
      setState(() {
        pixelOfImage = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
        selectedValues = sortedVal;
      });
    }

    void selectTextBlock(TextBlock block, Offset textPosition) {
      setState(() {
      selectedTextPart = block;
      position = textPosition;
     });
  }

  @override
  Widget build(BuildContext context) {
    if (pixelOfImage == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1118),
        foregroundColor: Colors.white,
        title: const Text('Edit Text'),
      ),

       body: LayoutBuilder(
        builder: (context, constraints) {
          final sizeOfBox = Size(constraints.maxWidth, constraints.maxHeight);
          final display = displayRect(sizeOfBox, pixelOfImage!);
          final scaleX = display.width / pixelOfImage!.width;
          final scaleY = display.height / pixelOfImage!.height;

          return GestureDetector(
            onTap: cancelTextSelection,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.file(
                    File(widget.page.path),
                    fit: BoxFit.contain,
                  ),
                ),

                for (final block in selectedValues!)
                  Positioned(

                    left: display.left + block.boundingBox.left * scaleX,
                    top: display.top + block.boundingBox.top * scaleY,
                    width: block.boundingBox.width * scaleX,
                    height: block.boundingBox.height * scaleY,

                    child: GestureDetector(
                      onTap: () {
                        final tap = Offset(
                          display.left + block.boundingBox.left * scaleX,
                          display.top + block.boundingBox.top * scaleY,
                        );
                        selectTextBlock(block, tap);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF4A9EFF),
                            width: selectedTextPart == block ? 2 : 1,
                          ),
                          color: const Color(0xFF4A9EFF).withValues(
                            alpha: selectedTextPart == block ? 0.18 : 0.08,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (selectedTextPart != null && position != null)
                  Positioned(
                    left: position!.dx,
                    top: (position!.dy - 46).clamp(0, double.infinity),
                    child: Material(
                      color: const Color(0xFF0D1118),
                      borderRadius: BorderRadius.circular(10),
                      elevation: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: openEdit,
                            icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                            label: const Text('Edit Text', style: TextStyle(color: Colors.white)),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: selectedTextPart!.text));
                              cancelTextSelection();
                            },
                            icon: const Icon(Icons.copy, color: Colors.white, size: 16),
                            label: const Text('Copy', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
          ));
        })
    );
  }

  void openEdit() {
    if (selectedTextPart == null) return;
    final block = selectedTextPart!;
    final existingText = correctedText[block] ?? block.text;
    final controller = TextEditingController(text: existingText);

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
              autofocus: true,
              maxLines: null,
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
                      correctedText[block] = controller.text;
                    });
                    Navigator.pop(context);
                    cancelTextSelection();
                  },
                  child: const Text('Save', style: TextStyle(color: Color(0xFF4A9EFF))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void cancelTextSelection() {
    setState(() {
      selectedTextPart = null;
      position = null;
    });
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
}