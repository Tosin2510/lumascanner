import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lumascanner/action_icon_button.dart';
import 'package:lumascanner/services/export_service.dart';
import 'package:lumascanner/services/pdf_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ScannedDocument {
  final String pathToPdf;
  final String fileName;
  final DateTime dateCreatedOrEdited;
  int noOfPages = 0;
  Uint8List? thumbnailImage;

  ScannedDocument({
    required this.pathToPdf,
    required this.fileName,
    required this.dateCreatedOrEdited,
  });
}

class PdfDocsScreen extends StatefulWidget {
  const PdfDocsScreen({super.key});

  @override
  State<PdfDocsScreen> createState() => _PdfDocsScreen();
}

class _PdfDocsScreen extends State<PdfDocsScreen> {

  final ExportService exportService = ExportService();
  final PdfService pdfService = PdfService();
 
  List<ScannedDocument> docs = [];
  List<String> pathToSelectedDocs = [];
  bool isLoading = true;

  bool get isSelecting => pathToSelectedDocs.isNotEmpty;
 
  bool isBusy = false;

  @override
  void initState() {
    super.initState();
    loadPdfDocumentsFromSavedDirectory();
  }

  Future<Directory> getPdfsFromPlaceWhereSaved() async {
    return await getApplicationDocumentsDirectory();
  }

 Future<void> loadPdfDocumentsFromSavedDirectory() async {
  final pdfDirectory = await getPdfsFromPlaceWhereSaved();
  final pdfFilesInDirectory = pdfDirectory.listSync();
  final documents = <ScannedDocument>[];
  for (final file in pdfFilesInDirectory) {
    if (file is File && file.path.endsWith('.pdf')) {
      final fileDocs = ScannedDocument(
        pathToPdf: file.path,
        fileName: path.basenameWithoutExtension(file.path),
        dateCreatedOrEdited: file.statSync().modified,
      );

      // Added this to prevent the same document from loading multiple times and loading the thumbnail multiple times too.
      for (final doc in docs) {
        if (doc.pathToPdf == fileDocs.pathToPdf && doc.dateCreatedOrEdited == fileDocs.dateCreatedOrEdited) {
          fileDocs.thumbnailImage = doc.thumbnailImage;
          fileDocs.noOfPages = doc.noOfPages;
        }
      }

      documents.add(fileDocs);
    }
  }

  if (!mounted) return;
  setState(() {
    docs = documents;
    isLoading = false;
  });
 }

 @override
 Widget build(BuildContext context) {
  return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1118),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(isSelecting ? Icons.close : Icons.arrow_back),
          onPressed: () {
            if (isSelecting) {
              setState(() {
                pathToSelectedDocs = [];
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(isSelecting? '${pathToSelectedDocs.length} selected': 'scanned Docs'),
        actions: [
          if (isSelecting)
            TextButton(
              onPressed: () {
                setState(() {
                  pathToSelectedDocs = docs.map((doc) => doc.pathToPdf).toList();
                });
              },
              child: const Text('Select all', style: TextStyle(color: Color(0xFF4A9EFF)))
            )
        ]
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  if (isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No scanned documents found, go to landing page to start scanning.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final isSelected = pathToSelectedDocs.contains(doc.pathToPdf);

                      return ListTile(
                        tileColor: isSelected ? const Color(0xFF0D1118) : Colors.transparent,
                        title: Text(doc.fileName, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          doc.dateCreatedOrEdited.toString(),
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: isSelecting
                            ? Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined,
                                color: isSelected ? const Color(0xFF4A9EFF) : Colors.white38,
                              )
                            : null,
                        onTap: () {
                          if (isSelecting) {
                            setState(() {
                              if (isSelected) {
                                pathToSelectedDocs.remove(doc.pathToPdf);
                              } else {
                                pathToSelectedDocs.add(doc.pathToPdf);
                              }
                            });
                          }
                        },
                        onLongPress: () {
                          setState(() {
                            if (isSelected) {
                              pathToSelectedDocs.remove(doc.pathToPdf);
                            } else {
                              pathToSelectedDocs.add(doc.pathToPdf);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            if (isBusy)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            )
          ],
        ),

        bottomNavigationBar: BottomAppBar(
          color:const Color(0xFF0D1118),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ActionIconButton(
                icon: Icons.share,
                label: 'Share',
                onTap: () {
                  if (pathToSelectedDocs.length == 1) {
                    exportService.shareDocument(pathToSelectedDocs.first);
                  } else {
                    exportService.shareManyDocuments(pathToSelectedDocs);
                  }
                },
              ),
             
            ActionIconButton(
              icon: Icons.drive_file_rename_outline,
              label: 'Rename',
              onTap: pathToSelectedDocs.length == 1 ? renameSelectedDocs : null,
            ),
          ],
          ),
        )
      );
 }

 Future<void> renameSelectedDocs() async {
  final pathToDoc = pathToSelectedDocs.first;
  final oldName = path.basenameWithoutExtension(pathToDoc);
  final controller = TextEditingController(text: oldName);

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
              hintText: 'Enter new name',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)), 
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save', style: TextStyle(color: Color(0xFF4A9EFF))),
            )
          ]
      );
    }
  );
  if (newName == null || newName.isEmpty) return;
 }
}