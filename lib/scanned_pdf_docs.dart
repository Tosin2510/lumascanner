import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lumascanner/action_icon_button.dart';
import 'package:lumascanner/pdf_view_screen.dart';
import 'package:lumascanner/services/export_service.dart';
import 'package:lumascanner/services/pdf_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:share_plus/share_plus.dart';

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

  bool showAllDocuments = false;
  int noOfDocsToShowFirst = 10;

  @override
  void initState() {
    super.initState();
    loadPdfDocumentsFromSavedDirectory();
  }

  Future<Directory> getPdfsFromPlaceWhereSaved() async {
  final appDir = await getApplicationDocumentsDirectory();
  final pdfDocsDir = Directory(path.join(appDir.path, 'Documents'));

  if (!await pdfDocsDir.exists()) {
    await pdfDocsDir.create(recursive: true);
  }

  return pdfDocsDir;
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

  documents.sort((first, second) => second.dateCreatedOrEdited.compareTo(first.dateCreatedOrEdited));

  if (!mounted) return;
  setState(() {
    docs = documents;
    isLoading = false;
  });
  await loadThumbnailForPdfDocs();
 }

Future<void> openPdfDocument(ScannedDocument doc) async {
  setState(() {
    isBusy = true;
  });

  try {
    
    final pdfFile = await pdfx.PdfDocument.openFile(doc.pathToPdf);
    final pages = <XFile>[];

    for (int pageNumber = 1; pageNumber <= pdfFile.pagesCount; pageNumber++) {
      final page = await pdfFile.getPage(pageNumber);

      final pageImage = await page.render(
        width: page.width,
        height: page.height,
        format: pdfx.PdfPageImageFormat.png,
      );
      
      await page.close();

      if (pageImage != null) {
        final temporaryDir = await getTemporaryDirectory();
        final imagePath = path.join(
          temporaryDir.path,
          '${path.basenameWithoutExtension(doc.pathToPdf)}page$pageNumber.png',
        );

        await File(imagePath).writeAsBytes(pageImage.bytes);
        pages.add(XFile(imagePath));
      }

    }

    await pdfFile.close();
    if (!mounted) return;

    setState(() {
      isBusy = false;
    });

    if (pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load the pdf pages.'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewScreen(
          pdfPath: doc.pathToPdf,
          pages: pages,
        ),
      ),
    );

    await loadPdfDocumentsFromSavedDirectory();
  } catch (e) {
    if (!mounted) return;
    setState(() {
      isBusy = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the document.'),
      ),
    );
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
                        'No scanned documents found.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final docsToShow = showAllDocuments ? docs : docs.take(noOfDocsToShowFirst).toList();
                  final moreDocsExists = docs.length > noOfDocsToShowFirst;

                  return ListView.builder(
                    itemCount: docsToShow.length + (moreDocsExists ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == docsToShow.length) {
                        return TextButton(
                          onPressed: () {
                            setState(() {
                              showAllDocuments = !showAllDocuments;
                            });
                          },
                          child: Text(
                            showAllDocuments ? 'Show less' : 'View all ${docs.length} documents',
                            style: const TextStyle(color: Color(0xFF4A9EFF)),
                          ),
                        );
                      }

                      final doc = docsToShow[index];
                      final isSelected = pathToSelectedDocs.contains(doc.pathToPdf);
                      return ListTile(
                        tileColor: isSelected ? const Color(0xFF0D1118) : Colors.transparent,
                        leading: doc.thumbnailImage == null ? const Icon(Icons.picture_as_pdf_outlined, color: Colors.white38, size: 40)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(
                                  doc.thumbnailImage!,
                                  width: 44,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                        title: Text(doc.fileName, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          doc.noOfPages == 0 ? dateValAasText(doc.dateCreatedOrEdited) : '${doc.noOfPages} pages • ${dateValAasText(doc.dateCreatedOrEdited)}',
                          style: const TextStyle(color: Colors.white54),
                        ),

                        trailing: IconButton(
                          icon: Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isSelected ? const Color(0xFF4A9EFF) : Colors.white38,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isSelected) {
                                pathToSelectedDocs.remove(doc.pathToPdf);
                              } else {
                                pathToSelectedDocs.add(doc.pathToPdf);
                              }
                            });
                          }
                        ),
                        onTap: () {
                          if (isSelecting) {
                            setState(() {
                              if (isSelected) {
                                pathToSelectedDocs.remove(doc.pathToPdf);
                              } else {
                                pathToSelectedDocs.add(doc.pathToPdf);
                              }
                            });
                          } else {
                            openPdfDocument(doc);
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
            })
          ),
          ],
        ),

        bottomNavigationBar: isSelecting ? BottomAppBar(
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
              icon: Icons.delete_outline,
              label: 'Delete',
              onTap: isSelecting ? deleteSelectedDocs : null,
            ),
             
            ActionIconButton(
              icon: Icons.drive_file_rename_outline,
              label: 'Rename',
              onTap: pathToSelectedDocs.length == 1 ? renameSelectedDocs : null,
            ),
          ],
          ),
        ) : null  
      );
 }
 
 Future<void> deleteSelectedDocs() async {
  final noOfDocsToDel = pathToSelectedDocs.length;

  final confirmedDel = await showDialog(
    context: context, 
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0D1118),
        title: Text(
          noOfDocsToDel == 1 ? 'Delete this document?' : 'Delete $noOfDocsToDel?',
          style: const TextStyle(color: Colors.white)
        ),
        content: Text(
          'This action cannot be undone',
          style: const TextStyle(color: Colors.white54)
        ),
        actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
        ] 
      );
    }
  );

  if (confirmedDel != true) return;
  for (final pathToDoc in pathToSelectedDocs) {
    final file = File(pathToDoc);
    if (await file.exists()) {
      await file.delete();
    }
  }

  setState(() {
    pathToSelectedDocs = [];
  });
  loadPdfDocumentsFromSavedDirectory();
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
  if (!mounted) return;
  var replacedName =newName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  if (replacedName.toLowerCase().endsWith('.pdf')) {
    replacedName = replacedName.substring(0, replacedName.length - 4);
  }

  final newPath = path.join(path.dirname(pathToDoc), '$replacedName.pdf');
  if (newPath == pathToDoc) return;

  if (File(newPath).existsSync()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A document with this name already exists.'))
    );
    return;
  }

  
  try {
  await File(pathToDoc).rename(newPath);

  setState(() {
    pathToSelectedDocs = [];
  });

  await loadPdfDocumentsFromSavedDirectory();

} catch (e) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Could not rename document.'),
    ),
  );
}
 }

 String digit(int numb) {
  return numb.toString().padLeft(2, '0');
 }

 String dateValAasText(DateTime date) {
  return '${digit(date.day)}-${digit(date.month)}-${date.year} ${digit(date.hour)}:${digit(date.minute)}';
 }

Future<void> loadThumbnailForPdfDocs() async {
  for (final doc in docs) {
    if (doc.thumbnailImage != null) continue;

    try {
      final pdfFile = await pdfx.PdfDocument.openFile(doc.pathToPdf);

      final firstPage = await pdfFile.getPage(1);

      final pageImage = await firstPage.render(
        width: firstPage.width * 0.4,
        height: firstPage.height * 0.4,
        format: pdfx.PdfPageImageFormat.jpeg,
        backgroundColor: '#FFFFFF',
      );

      await firstPage.close();

      final pageNumbers = pdfFile.pagesCount;

      await pdfFile.close();

      if (!mounted) return;

      setState(() {
        doc.thumbnailImage = pageImage?.bytes;
        doc.noOfPages = pageNumbers;
      });
    } catch (e) {
      debugPrint('Error reading document: $e');
    }
  }
}
}