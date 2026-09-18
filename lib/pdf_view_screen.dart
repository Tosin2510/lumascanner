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
  final ExportService _exportService = ExportService();
  late String _currentpdfPath;
  late String _currentpdfName;

  @override
  void initState() {
    super.initState();
    _currentpdfPath = widget.pdfPath;
    _currentpdfName = path.basenameWithoutExtension(_currentpdfPath);
  }

  Future<void> _addExtraPages() async {
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
        _editPages(extraPages: additionalImages);
      }
    } else if (decision == 'camera') {
      final value = await Navigator.push<List<XFile>>(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(returnPreviewPages: true),
        )
      );
      if (value != null && value.isNotEmpty) {
        _editPages(extraPages: value);
      }
    }
  }

  void _editPages({List<XFile>? extraPages}) {
    final completePages = [...widget.pages, ...?extraPages];
    Navigator.pop(context, completePages);
  }

  Future<void> _renameDocument() async {
    final TextEditingController controller = TextEditingController(text: _currentpdfName);
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
      final directory = path.dirname(_currentpdfPath);
      final newPath = path.join(directory, "$newName.pdf");
      final renamedFile = await File(_currentpdfPath).rename(newPath);

      setState(() {
        _currentpdfPath = renamedFile.path;
        _currentpdfName = newName;
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
          onTap: _renameDocument,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  _currentpdfName,
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
        key: ValueKey(_currentpdfPath),
        build: (format) => File(_currentpdfPath).readAsBytes(),
        useActions: false,
        scrollViewDecoration: const BoxDecoration(color: Colors.black),
        previewPageMargin: EdgeInsets.zero,
        pdfPreviewPageDecoration: const BoxDecoration(),
        padding: EdgeInsets.zero,
        canChangePageFormat: false,
        canChangeOrientation: false,
        loadingWidget: const Center(child: CircularProgressIndicator(color: Colors.white)),
        allowPrinting: true,
        allowSharing: false,
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share',
              onPressed: () => _exportService.shareDocument(_currentpdfPath),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add Page',
              onPressed: () => _addExtraPages(),
            ),
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: 'Edit',
              onPressed: () => _editPages(),
            ),
          ]
        )
      )
    );
  }
}