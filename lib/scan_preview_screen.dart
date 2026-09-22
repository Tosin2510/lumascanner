import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lumascanner/crop_screen.dart';
import 'package:lumascanner/pdf_view_screen.dart';
import 'package:lumascanner/perspective_transform_service.dart';
import 'package:lumascanner/services/pdf_service.dart';

class ScanPreviewScreen extends StatefulWidget {
  final List<XFile> images;
  const ScanPreviewScreen({
    super.key,
    required this.images,
  });
  @override
  State<ScanPreviewScreen> createState() => _ScanPreviewScreenState();
}

class _ScanPreviewScreenState extends State<ScanPreviewScreen> {
  final pdfService = PdfService();
  int currentIndex = 0;
  late PageController pageController;
  late List<XFile> pages;
  final _perspectiveTransform = PerspectiveTransformService();

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    pages = List.from(widget.images);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> pdfPart() async {
    final pathToPdf = await pdfService.createdPdf(pages);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewScreen(
          pdfPath: pathToPdf,
          pages: pages,
        ),
      ),
    );
  }

  Future<void> cropPart(int index) async {
    final val = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CropScreen(pathToImage: pages[index].path),
      )
    );

    if (val != null) {
      final transformedImagePath = await _perspectiveTransform.transformImage(
        imagePath: val['imagePath'],
        topLeft: val['topLeft'],
        topRight: val['topRight'],
        bottomLeft: val['bottomLeft'],
        bottomRight: val['bottomRight'],
        sizeOfBox: val['sizeOfBox'],
      );
      setState(() {
          pages[index] = XFile(transformedImagePath);
      });
    }
  }

  void deleteSelected() async {
    setState(() {
      pages.removeAt(currentIndex);
      if (currentIndex >= pages.length) {
        currentIndex = pages.length - 1;
      }
      if (pages.isNotEmpty) {
        pageController.jumpToPage(currentIndex);
      }
    });
  }

  void onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final move = pages.removeAt(oldIndex); 
      pages.insert(newIndex, move);
      currentIndex = newIndex;
      pageController.jumpToPage(currentIndex);
    });
  }

  void selectPage(int index) {
    setState((){
      currentIndex = index;
      pageController.jumpToPage(currentIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final showThumbnail = pages.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed:() => Navigator.pop(context),
          icon: Icon(Icons.close, color: Colors.white, size: 27)
        ),
        actions: [
          TextButton(
            onPressed: () => pdfPart(),
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              )
            )
          )
        ]
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                PageView.builder(         
                  controller: pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) => setState(() => currentIndex = index),
                  itemBuilder: (context, index) => InteractiveViewer(
                    child: Image.file(
                      File(pages[index].path),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.black,
                    onPressed: () => cropPart(currentIndex),
                    child: const Icon(Icons.crop, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          if (showThumbnail)... [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Page ${currentIndex + 1} of ${pages.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500
                )
              )
            ),
            SizedBox(
              height: 70,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                onReorder: onReorder,
                itemCount: pages.length, 
                itemBuilder: (context, index) {
                  final isPicked = index == currentIndex;
                  return Padding(
                    key: ValueKey(pages[index].path),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => selectPage(index),
                      child: Stack(
                        children: [
                          Container(
                            width: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: isPicked ? Colors.blueAccent 
                                : Colors.transparent, 
                                width: 2
                              )
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(pages[index].path),
                                    fit: BoxFit.cover,
                                  ),
                                  if (isPicked)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: deleteSelected,
                                      child: Container(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        child: const Icon(Icons.delete, color: Colors.white54, size: 23)
                                      )
                                    )
                                  )
                                ]
                              )
                            )
                          )
                        ]
                      )
                    )
                  );
                }
              )
            )
        ],
      ]),
    );
  }
}
