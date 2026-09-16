import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
  int _currentIndex = 0;
  late PageController _pageController;
  late List<XFile> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = List.from(widget.images);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _deleteSelected() async {
    setState(() {
      _pages.removeAt(_currentIndex);
      if (_currentIndex >= _pages.length) {
        _currentIndex = _pages.length - 1;
      }
      if (_pages.isNotEmpty) {
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final move = _pages.removeAt(oldIndex); 
      _pages.insert(newIndex, move);
      _currentIndex = newIndex;
      _pageController.jumpToPage(_currentIndex);
    });
  }

  void _selectPage(int index) {
    setState((){
      _currentIndex = index;
      _pageController.jumpToPage(_currentIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final showThumbnail = _pages.length > 1;

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
            onPressed: () =>Navigator.pop(context, _pages),
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
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) => InteractiveViewer(
                child: Image.file(
                  File(_pages[index].path),
                  fit: BoxFit.contain,
                )
              )
            )
          ),
          if (showThumbnail)... [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Page ${_currentIndex + 1} of ${_pages.length}',
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
                onReorder: _onReorder,
                itemCount: _pages.length, 
                itemBuilder: (context, index) {
                  final isPicked = index == _currentIndex;
                  return Padding(
                    key: ValueKey(_pages[index].path),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => _selectPage(index),
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
                                    File(_pages[index].path),
                                    fit: BoxFit.cover,
                                  ),
                                  if (isPicked)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: _deleteSelected,
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
