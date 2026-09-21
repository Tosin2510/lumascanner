import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lumascanner/corner_part.dart';
import 'package:image/image.dart' as image;

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
  Size? _pixelOfImage;
  Offset _startingPointOfImageInBox = Offset.zero;

  Rect _calculateActualImageRectangle(Size sizeOfBox, Size imageSize) {
    final boxAspectRatio = sizeOfBox.width / sizeOfBox.height;
    final imageAspectRatio = imageSize.width / imageSize.height;

    double width;
    double height;

    if (imageAspectRatio > boxAspectRatio) {
       width = sizeOfBox.width;
       height = sizeOfBox.width / imageAspectRatio;
    } else {
       height = sizeOfBox.height;
       width = sizeOfBox.height * imageAspectRatio;
    }

    final xVal = (sizeOfBox.width - width)/ 2;
    final yVal = (sizeOfBox.height - height)/ 2;

    return Rect.fromLTWH(xVal, yVal, width, height);
  }


// I am adding this functions for the crop screen midpoints.

  Offset? get _topMiddlePart => (topLeft != null && topRight != null)
    ? Offset((topLeft!.dx + topRight!.dx) / 2, (topLeft!.dy + topRight!.dy) / 2)
    : null;
  Offset? get _leftMiddlePart => (topLeft != null && bottomLeft != null)
    ? Offset((topLeft!.dx + bottomLeft!.dx) / 2, (topLeft!.dy + bottomLeft!.dy) / 2)
    : null;
  Offset? get _rightMiddlePart => (topRight != null && bottomRight != null)
    ? Offset((topRight!.dx + bottomRight!.dx) / 2, (topRight!.dy + bottomRight!.dy) / 2)
    : null;
  Offset? get _bottomMiddlePart => (bottomLeft != null && bottomRight != null)
    ? Offset((bottomLeft!.dx + bottomRight!.dx) / 2, (bottomLeft!.dy + bottomRight!.dy) / 2)
    : null;

  Future<void> _getSizeOfImage() async {
  final imageBytes = await File(widget.pathToImage).readAsBytes();
  final decoded = image.decodeImage(imageBytes)!;
  setState(() {
    _pixelOfImage = Size(decoded.width.toDouble(), decoded.height.toDouble());
  });
}

  void _corners(Size boxSize) {
    if (topLeft != null)  return;
    final actualImageRectangle = _calculateActualImageRectangle(boxSize, _pixelOfImage!);
    const space = 24.0;
      setState(() {
        _sizeOfBox = actualImageRectangle.size;
        _startingPointOfImageInBox = actualImageRectangle.topLeft;
        topLeft = Offset(actualImageRectangle.left + space, actualImageRectangle.top + space);
        topRight = Offset(actualImageRectangle.right - space, actualImageRectangle.top + space);
        bottomLeft = Offset(actualImageRectangle.left + space, actualImageRectangle.bottom - space);
        bottomRight = Offset(actualImageRectangle.right - space, actualImageRectangle.bottom - space);
      });
    }

  void _doCropping() {
    if (topLeft != null && topRight != null && bottomLeft != null && bottomRight != null) {
      Navigator.pop(context, {
        'topLeft': topLeft! - _startingPointOfImageInBox,
        'topRight': topRight! - _startingPointOfImageInBox,
        'bottomLeft': bottomLeft! - _startingPointOfImageInBox,
        'bottomRight': bottomRight! - _startingPointOfImageInBox,
        'sizeOfBox': _sizeOfBox,
        'imagePath': widget.pathToImage,
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getSizeOfImage();
  }

  @override
  Widget build(BuildContext context) {
    if (_pixelOfImage == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                _buildDraggableMidPoints('top', _topMiddlePart),
                _buildDraggableMidPoints('left', _leftMiddlePart),
                _buildDraggableMidPoints('right', _rightMiddlePart),
                _buildDraggableMidPoints('bottom', _bottomMiddlePart)
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
        onPanUpdate:(details) => _midPointParts(corner, details.delta),
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
    final minvalX = _startingPointOfImageInBox.dx;
    final minvalY = _startingPointOfImageInBox.dy;
    final maxvalX = _startingPointOfImageInBox.dx + _sizeOfBox!.width;
    final maxvalY = _startingPointOfImageInBox.dy + _sizeOfBox!.height;
    return Offset(
      position.dx.clamp(minvalX, maxvalX),
      position.dy.clamp(minvalY, maxvalY)
    );
  }

  void _midPointParts(String corner, Offset delta) {
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

void _cornerParts(String edge, Offset delta) {
  setState(() {
    switch (edge) {
      case 'top':
        topLeft = _hold(topLeft! + delta);
        topRight = _hold(topRight! + delta);
        break;
      case 'bottom':
        bottomLeft = _hold(bottomLeft! + delta);
        bottomRight = _hold(bottomRight! + delta);
        break;
      case 'left':
        topLeft = _hold(topLeft! + delta);
        bottomLeft = _hold(bottomLeft! + delta);
        break;
      case 'right':
        topRight = _hold(topRight! + delta);
        bottomRight = _hold(bottomRight! + delta);
        break;
    }
  });
}

  Widget _buildDraggableMidPoints(String edge, Offset? position) {
    if (position == null) return const SizedBox.shrink();
    return Positioned(
      left: position.dx - 12,
      top: position.dy - 12,
      child: GestureDetector(
        onPanUpdate: (details) => _cornerParts(edge, details.delta),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blueAccent, width: 2),
          ),
        ),
      ),
      );
  }
}
