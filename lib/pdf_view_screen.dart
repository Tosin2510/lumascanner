import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumascanner/camera_screen.dart';
import 'package:lumascanner/services/export_service.dart';
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
  late String currentpdfPath;
  late String currentpdfName;

  @override
  void initState() {
    super.initState();
    currentpdfPath = widget.pdfPath;
    currentpdfName = path.basenameWithoutExtension(currentpdfPath);
  }

  Future<void> addExtraPages() async {
    final decision = await showModalBottomSheet(
      context: context, 
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Select from Gallery'),
              onTap: () => Navigator.of(context).pop('gallery'),
            )
          ]
        )
      )
    );

    if (!mounted) return;
    if (decision == 'gallery') {
      final imagePicker = ImagePicker();
      final additionalImages = await imagePicker.pickMultiImage();
      if (additionalImages.isNotEmpty) {
        editPages(extraPages: additionalImages);
      }
    } else if (decision == 'camera') {
      final value = await Navigator.push<List<XFile>>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(returnPreviewPages: true),
        )
      );
      if (value != null && value.isNotEmpty) {
        editPages(extraPages: value);
      }
    }
  }

  void editPages({List<XFile>? extraPages}) {
    final completePages = [...widget.pages, ...?extraPages];
    Navigator.pop(context, completePages);
  }

  Future<void> renameDocument() async {
    final TextEditingController controller = TextEditingController(text: currentpdfName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Document'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter document name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ]
        );
      }
    );
    if (newName != null && newName.isNotEmpty) {
      final directory = path.dirname(currentpdfPath);
      final newPath = path.join(directory, "$newName.pdf");
      final renamedFile = await File(currentpdfPath).rename(newPath);

      setState(() {
        currentpdfPath = renamedFile.path;
        currentpdfName = newName;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                  currentpdfName,
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
        key: ValueKey(currentpdfPath),
        build: (format) => File(currentpdfPath).readAsBytes(),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share',
              onPressed: () => exportService.shareDocument(currentpdfPath),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add Page',
              onPressed: () => addExtraPages(),
            ),
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Edit',
              onPressed: () => editPages(),
            ),
          ]
        )
      )
    );
  }
}