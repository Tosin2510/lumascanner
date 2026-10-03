import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ExtractedTextScreen extends StatefulWidget {
  final List<XFile> pages;
  final List<RecognizedText> pageResults;

  const ExtractedTextScreen({
    super.key,
    required this.pages,
    required this.pageResults,
  });

  @override
  State<ExtractedTextScreen> createState() => _ExtractedTextScreenState();
}

class _ExtractedTextScreenState extends State<ExtractedTextScreen> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: buildFullText());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String buildFullText() {
    final buffer = StringBuffer();

    for (int i = 0; i < widget.pageResults.length; i++) {
      final sortedBlocks = List<TextBlock>.from(widget.pageResults[i].blocks)
        ..sort((a, b) {
          final compareTop = a.boundingBox.top.compareTo(b.boundingBox.top);
          if (compareTop != 0) return compareTop;
          return a.boundingBox.left.compareTo(b.boundingBox.left);
        });

      if (widget.pageResults.length > 1) {
        buffer.writeln('Page ${i + 1}');
      }
      for (final block in sortedBlocks) {
        buffer.writeln(block.text);
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  void copyToClipboard() {
    Clipboard.setData(ClipboardData(text: controller.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1118),
        foregroundColor: Colors.white,
        title: const Text('Extracted Text'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy',
            onPressed: copyToClipboard,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: null,
          expands: true,
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      ),
    );
  }
}