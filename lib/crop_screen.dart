import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lumascanner/corner_part.dart';
class CropScreen extends StatefulWidget {
  final String pathToImage;
  const CropScreen({
    super.key,
    required this.pathToImage,
  });
  @override
  State<CropScreen> createState() => _CropScreenState();
}
class _CropScreenState extends State<CropScreen> {
  Offset? topLeft;
  Offset? topRight;
  Offset? bottomLeft;
  Offset? bottomRight;
  Size? _sizeOfBox;

  void _corners(Size size) {
    if (topLeft != null)  return;
    const space = 24.0;
      setState(() {
        _sizeOfBox = size;
        topLeft = Offset(space, space);
        topRight = Offset(size.width - space, space);
        bottomLeft = Offset(space, size.height - space);
        bottomRight = Offset(size.width - space, size.height - space);
      });
    }

  void _doCropping() {
    if (topLeft != null && topRight != null && bottomLeft != null && bottomRight != null) {
      Navigator.pop(context, {
        'topLeft': topLeft,
        'topRight': topRight,
        'bottomLeft': bottomLeft,
        'bottomRight': bottomRight,
        'sizeOfBox': _sizeOfBox,
        'imagePath': widget.pathToImage,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _doCropping,
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.blueAccent,
              )
            )
          ),
        ]
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          WidgetsBinding.instance.addPostFrameCallback((_) => _corners(size));
          return Stack(
            children: [
              Positioned.fill(
                child: Image.file(
                  File(widget.pathToImage),
                  fit: BoxFit.contain,
                ),
              ),
              if (topLeft != null)...[
                Positioned.fill(
                  child: CustomPaint(
                    painter: CornerPart(topL: topLeft!, topR: topRight!, bottomL: bottomLeft!, bottomR: bottomRight!)
                  )
                ),
                _buildDraggableCorner('topLeft', topLeft),
                _buildDraggableCorner('topRight', topRight),
                _buildDraggableCorner('bottomLeft', bottomLeft),
                _buildDraggableCorner('bottomRight', bottomRight),
              ]
            ]
         );
       }
     )
   );
  }

  Widget _buildDraggableCorner(String corner, Offset? position) {
    if (position == null) return const SizedBox.shrink();
    return Positioned(
      left: position.dx - 15,
      top: position.dy - 15,
      child: GestureDetector(
        onPanUpdate:(details) => _keepTrackOfCorner(corner, details.delta),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          )
        )
      )
    );
  }

  Offset _hold(Offset position) {
    if (_sizeOfBox == null) return position;
    return Offset(
      position.dx.clamp(0.0, _sizeOfBox!.width),
      position.dy.clamp(0.0, _sizeOfBox!.height)
    );
  }

  void _keepTrackOfCorner(String corner, Offset delta) {
    setState(() {
      switch (corner) {
        case 'topLeft':
          topLeft = _hold(topLeft! + delta);
          break;
        case 'topRight':
          topRight = _hold(topRight! + delta);
          break;
        case 'bottomLeft':
          bottomLeft = _hold(bottomLeft! + delta);
          break;
        case 'bottomRight':
          bottomRight = _hold(bottomRight! + delta);
          break;
      }
    });
  }

}
