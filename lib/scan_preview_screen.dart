import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lumascanner/crop_screen.dart';
import 'package:lumascanner/pdf_view_screen.dart';
import 'package:lumascanner/perspective_transform_service.dart';
import 'package:lumascanner/services/action_icon_button.dart';
import 'package:lumascanner/services/image_enhancement_service.dart';
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

  final enhancementService = ImageEnhancementService();

  
  bool isEnhancementHappening = true;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    pages = List.from(widget.images);
    enhancePages();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }


  Future<void> enhancePages() async {
    await Future.wait(widget.images.map((original) async {
      try {
        final enhancedPath = await enhancementService.autoEnhance(original.path);
        if (!mounted) return;

        final indexVal = pages.indexWhere((p) => p.path == original.path);
        if (indexVal == -1) return;
        setState(() => pages[indexVal] = XFile(enhancedPath));
      } catch (e) {
        debugPrint('Enhance failed for ${original.path}: $e'); 
      }
    }));

    if (mounted) setState(() => isEnhancementHappening = false);
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
      if (!mounted || index >= pages.length) return;
      setState(() {
          pages[index] = XFile(transformedImagePath);
      });
    }
  }

  void deleteSelected() {
    setState(() {
      pages.removeAt(currentIndex);
      if (currentIndex >= pages.length) {
        currentIndex = pages.length - 1;
      }
    });
    if (pages.isEmpty) {
      Navigator.pop(context);
    } else {
      pageController.jumpToPage(currentIndex);
    }
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
            onPressed: isEnhancementHappening ? null : pdfPart,
            child: const Text(
              'Done',
              style: TextStyle(
                color: Color(0xFF4A9EFF),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              )
            )
          )
        ],
        bottom: isEnhancementHappening
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3, color: Color(0xFF4A9EFF)),
              )
            : null,
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
              ],
            ),
          ),
          
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1118),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4A9EFF).withValues(alpha: 0.2)),
            ),

            child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ActionIconButton(
                  icon: Icons.crop_rounded,
                  label: 'Crop',
                  onTap: () => cropPart(currentIndex),
                ),
                if (showThumbnail)
                  ActionIconButton(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Reorder',
                    onTap: reorderPart,
                  ),
              ]
            )
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
                onReorderItem: onReorder,
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
                                color: isPicked ? const Color(0xFF4A9EFF) 
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
                                    cacheWidth: 150,
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

  void reorderPart() {
    showModalBottomSheet(
      context: context, 
      backgroundColor: const Color(0xFF0D1118),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      builder: (contxt) => StatefulBuilder(builder: 
      (context, setValState) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              const SizedBox(height: 12,),
               Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Drag the handle to reorder pages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: pages.length,
                  onReorderItem: (oldIndex, newIndex) {
                    onReorder(oldIndex, newIndex);
                    setValState(() {});
                  },
                  itemBuilder: (context, index) => ListTile(
                    key: ValueKey(pages[index].path),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(pages[index].path),
                        width: 44,
                        height: 56,
                        fit: BoxFit.cover,
                        cacheWidth: 120,
                      ),
                    ),

                    title: Text(
                      'Page ${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),

                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(
                        Icons.drag_handle_rounded,
                        color: Colors.white54,
                      ),
                    ),
                  )
                )
              )
            ],
          )

      )

      )
    );
  }
}