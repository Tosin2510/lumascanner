import 'dart:io';
import 'package:document_scan/document_scan.dart';
import 'package:flutter/material.dart';
import 'package:lumascanner/automatic_edge_detection.dart';
import 'package:lumascanner/corner_part.dart';
import 'package:image/image.dart' as image;
import 'package:lumascanner/services/action_icon_button.dart';
import 'package:lumascanner/services/image_rotation_service.dart';

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
  Size? sizeOfBox;
  Size? pixelOfImage;
  Offset startingPointOfImageInBox = Offset.zero;
  bool isCropping = false;
  Offset? currentDragPosition;

  final automaticEdgeDetection = AutomaticEdgeDetection();
  DocumentCorners? detectedCorners;

  // Cropped can now rotate... so I track its path here.
  late String currentImagePath;
  final rotationService = ImageRotationService();
  bool isRotating = false;
  
  Rect calculateActualImageRectangle(Size sizeOfBox, Size imageSize) {
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


// I am adding this functions to calculate the crop screen midpoints.

  Offset? get topMiddlePart => (topLeft != null && topRight != null)
    ? Offset((topLeft!.dx + topRight!.dx) / 2, (topLeft!.dy + topRight!.dy) / 2)
    : null;
  Offset? get leftMiddlePart => (topLeft != null && bottomLeft != null)
    ? Offset((topLeft!.dx + bottomLeft!.dx) / 2, (topLeft!.dy + bottomLeft!.dy) / 2)
    : null;
  Offset? get rightMiddlePart => (topRight != null && bottomRight != null)
    ? Offset((topRight!.dx + bottomRight!.dx) / 2, (topRight!.dy + bottomRight!.dy) / 2)
    : null;
  Offset? get bottomMiddlePart => (bottomLeft != null && bottomRight != null)
    ? Offset((bottomLeft!.dx + bottomRight!.dx) / 2, (bottomLeft!.dy + bottomRight!.dy) / 2)
    : null;



  Future<void> getSizeOfImage() async {
  final imageBytes = await File(currentImagePath).readAsBytes();
  final decodedImage = image.decodeImage(imageBytes)!;

// Added this to run the edge detection since the image pixel dimension is already available...
  final corners = await automaticEdgeDetection.detectEdges(currentImagePath);
  
  if (!mounted) return;
  setState(() {
    pixelOfImage = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
    detectedCorners = corners;
  });
}

// The condition i added here either uses detection if it is available
// Otherwise, it uses what i already have there.

  void corners(Size boxSize) {
    if (topLeft != null)  return;
    final actualImageRectangle = calculateActualImageRectangle(boxSize, pixelOfImage!);
    sizeOfBox = actualImageRectangle.size;   
    startingPointOfImageInBox = actualImageRectangle.topLeft;

    if (detectedCorners != null) {
      final pixCorners = detectedCorners!.toPixels(
        pixelOfImage!.width.toInt(), 
        pixelOfImage!.height.toInt(),
      );


      final xVal = actualImageRectangle.width/pixelOfImage!.width;
      final yVal = actualImageRectangle.height/pixelOfImage!.height;

      Offset convertToScreenCoordinates(Offset imagePoint) =>
        Offset(
          actualImageRectangle.left + imagePoint.dx * xVal,
          actualImageRectangle.top + imagePoint.dy * yVal
        );

        setState(() {
          topLeft = convertToScreenCoordinates(Offset(pixCorners[0].x, pixCorners[0].y));
          topRight = convertToScreenCoordinates(Offset(pixCorners[1].x, pixCorners[1].y));
          bottomRight = convertToScreenCoordinates(Offset(pixCorners[2].x, pixCorners[2].y));
          bottomLeft = convertToScreenCoordinates(Offset(pixCorners[3].x, pixCorners[3].y));
        });
      } else {
          const space = 24.0;
            setState(() {
              topLeft = Offset(actualImageRectangle.left + space, actualImageRectangle.top + space);
              topRight = Offset(actualImageRectangle.right - space, actualImageRectangle.top + space);
              bottomLeft = Offset(actualImageRectangle.left + space, actualImageRectangle.bottom - space);
              bottomRight = Offset(actualImageRectangle.right - space, actualImageRectangle.bottom - space);
            });
          }
        }

        void doCropping() {
          if (topLeft != null && topRight != null && bottomLeft != null && bottomRight != null) {
      Navigator.pop(context, {
        'topLeft': topLeft! - startingPointOfImageInBox,
        'topRight': topRight! - startingPointOfImageInBox,
        'bottomLeft': bottomLeft! - startingPointOfImageInBox,
        'bottomRight': bottomRight! - startingPointOfImageInBox,
        'sizeOfBox': sizeOfBox,
        'imagePath': currentImagePath,
      });
    }
  }

// Rotates the image file...runs automatic edge detection again.
  Future<void> rotateImage(int degrees) async {
    if (isRotating) return;
    setState(() => isRotating = true);
    try {
      final (rotatedPath, newWidth, newHeight) =
          await rotationService.rotateBasedOnImgSize(currentImagePath, degrees);
      final corners = await automaticEdgeDetection.detectEdges(rotatedPath);
      if (!mounted) return;
      setState(() {
        currentImagePath = rotatedPath;
        topLeft = null;
        topRight = null;
        bottomLeft = null;
        bottomRight = null;
        pixelOfImage = Size(newWidth.toDouble(), newHeight.toDouble());
        detectedCorners = corners;
      });
    } finally {
      if (mounted) setState(() => isRotating = false);
    }
  }

  void autoCrop() {
    if (detectedCorners == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document edges found')),
      );
      return;
    }
    setState(() => topLeft = null);
  }

  void selectAll() {
    if (sizeOfBox == null) return;
    final fullImage = startingPointOfImageInBox & sizeOfBox!;
    setState(() {
      topLeft = fullImage.topLeft;
      topRight = fullImage.topRight;
      bottomLeft = fullImage.bottomLeft;
      bottomRight = fullImage.bottomRight;
    });
  }

  @override
  void initState() {
    super.initState();
    currentImagePath = widget.pathToImage;
    getSizeOfImage();
  }

  @override
  Widget build(BuildContext context) {
    if (pixelOfImage == null || isRotating) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color(0xFF0D1B33),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: doCropping,
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.blueAccent,
              )
            )
          ),
        ]
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFF0D1B33),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0xFF3D8BFF).withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ActionIconButton(
                icon: Icons.rotate_left_rounded,
                label: 'Left',
                onTap: () => rotateImage(270),
              ),
              ActionIconButton(
                icon: Icons.rotate_right_rounded,
                label: 'Right',
                onTap: () => rotateImage(90),
              ),

              ActionIconButton(
                icon: Icons.document_scanner_outlined,
                label: 'Automatic',
                onTap: autoCrop,
              ),
  
              ActionIconButton(
                icon: Icons.crop_free_rounded,
                label: 'All',
                onTap: selectAll,
              ),
            ],
          ),
        ),
      ),


      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          WidgetsBinding.instance.addPostFrameCallback((_) => corners(size));
          return Stack(
            children: [
              Positioned.fill(
                child: Image.file(
                  File(currentImagePath),
                  fit: BoxFit.contain,
                ),
              ),
              if (topLeft != null)...[
                Positioned.fill(
                  child: CustomPaint(
                    painter: CornerPart(topL: topLeft!, topR: topRight!, bottomL: bottomLeft!, bottomR: bottomRight!)
                  )
                ),

                buildDraggableCorner('topLeft', topLeft),
                buildDraggableCorner('topRight', topRight),
                buildDraggableCorner('bottomLeft', bottomLeft),
                buildDraggableCorner('bottomRight', bottomRight),
                buildDraggableMidPoints('top', topMiddlePart),
                buildDraggableMidPoints('left', leftMiddlePart),
                buildDraggableMidPoints('right', rightMiddlePart),
                buildDraggableMidPoints('bottom', bottomMiddlePart),

                if (isCropping && currentDragPosition != null) 
                  buildMagnifyingGlass(currentDragPosition!, size)
              ]
            ]
         );
       }
     )
   );
  }

  Widget buildDraggableCorner(String corner, Offset? position) {
    if (position == null) return const SizedBox.shrink();
    return Positioned(
      left: position.dx - 15,
      top: position.dy - 15,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            isCropping = true;
          });
        },
        onPanUpdate:(details) { midPointParts(corner, details.delta);
        setState(() => currentDragPosition = trackDragCorner(corner));
        },
      onPanEnd: (_) => setState(() => isCropping = false),
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

  Offset? trackDragCorner(String corner) {
    switch (corner) {
      case 'topLeft': return topLeft;
      case 'topRight': return topRight;
      case 'bottomLeft': return bottomLeft;
      case 'bottomRight': return bottomRight;
      default: return null;
    }
  }
  Offset hold(Offset position) {
    if (sizeOfBox == null) return position;
    final minvalX = startingPointOfImageInBox.dx;
    final minvalY = startingPointOfImageInBox.dy;
    final maxvalX = startingPointOfImageInBox.dx + sizeOfBox!.width;
    final maxvalY = startingPointOfImageInBox.dy + sizeOfBox!.height;

    const valToConsiderSnapInPlace = 12.0;

   double snaptoX = position.dx.clamp(minvalX, maxvalX);
  double snaptoY = position.dy.clamp(minvalY, maxvalY);

  // Snap to the image's actual edges when close
  if ((snaptoX - minvalX).abs() < valToConsiderSnapInPlace) snaptoX = minvalX;
  if ((snaptoX - maxvalX).abs() < valToConsiderSnapInPlace) snaptoX = maxvalX;
  if ((snaptoY - minvalY).abs() < valToConsiderSnapInPlace) snaptoY = minvalY;
  if ((snaptoY - maxvalY).abs() < valToConsiderSnapInPlace) snaptoY = maxvalY;

  return Offset(snaptoX, snaptoY);
  }

  void midPointParts(String corner, Offset delta) {
  setState(() {
    switch (corner) {
      case 'topLeft':
        topLeft = hold(topLeft! + delta);
        break;
      case 'topRight':
        topRight = hold(topRight! + delta);
        break;
      case 'bottomLeft':
        bottomLeft = hold(bottomLeft! + delta);
        break;
      case 'bottomRight':
        bottomRight = hold(bottomRight! + delta);
        break;
    }
  });
}

void cornerParts(String edge, Offset delta) {
  setState(() {
    switch (edge) {
      case 'top':
        topLeft = hold(topLeft! + delta);
        topRight = hold(topRight! + delta);
        break;
      case 'bottom':
        bottomLeft = hold(bottomLeft! + delta);
        bottomRight = hold(bottomRight! + delta);
        break;
      case 'left':
        topLeft = hold(topLeft! + delta);
        bottomLeft = hold(bottomLeft! + delta);
        break;
      case 'right':
        topRight = hold(topRight! + delta);
        bottomRight = hold(bottomRight! + delta);
        break;
    }
  });
}

  Widget buildDraggableMidPoints(String edge, Offset? position) {
    if (position == null) return const SizedBox.shrink();
    return Positioned(
      left: position.dx - 12,
      top: position.dy - 12,
      child: GestureDetector(
        onPanStart: (_) => setState(() => isCropping = true),
        onPanUpdate: (details) {cornerParts(edge, details.delta);
        setState(() => currentDragPosition = position + details.delta);
      },
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

 
  Widget buildMagnifyingGlass(Offset position, Size sizeOfBox) {
  const magnifyingGlassSize = 170.0;
  const zoomExtent = 3.0;

   Offset zoom(Offset corner) {
    return (corner - startingPointOfImageInBox) * zoomExtent;
  }


  final localPosition = position - startingPointOfImageInBox;

  final xVal = (magnifyingGlassSize / 2) - (localPosition.dx * zoomExtent);
  final yVal = (magnifyingGlassSize / 2) - (localPosition.dy * zoomExtent);

  final showAbove = position.dy - magnifyingGlassSize - 30 > 0;
  final top = showAbove ? position.dy - magnifyingGlassSize - 30 : position.dy + 30;
  final left = (position.dx - magnifyingGlassSize / 2).clamp(0.0, double.infinity);

  return Positioned(
    left: left,
    top: top,
    child: IgnorePointer(
      child: Container(
        width: magnifyingGlassSize,
        height: magnifyingGlassSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
        ),
        child: ClipOval(
          child: OverflowBox(
            maxWidth: sizeOfBox.width * zoomExtent,
            maxHeight: sizeOfBox.height * zoomExtent,

            child: OverflowBox(
                maxWidth: sizeOfBox.width * zoomExtent,
                maxHeight: sizeOfBox.height * zoomExtent,
                child: Transform.translate(
                  offset: Offset(xVal, yVal),                 
                  child: SizedBox(
                    width: sizeOfBox.width * zoomExtent,
                    height: sizeOfBox.height * zoomExtent,
                    child: Stack(
                      children: [
                        Image.file(
                          File(currentImagePath),
                          width: sizeOfBox.width * zoomExtent,
                          height: sizeOfBox.height * zoomExtent,
                          fit: BoxFit.fill,
                        ),
                        CustomPaint(
                        size: Size(sizeOfBox.width * zoomExtent, sizeOfBox.height * zoomExtent),
                        painter: CornerPart(
                          topL: zoom(topLeft!),
                          topR: zoom(topRight!),
                          bottomL: zoom(bottomLeft!),
                          bottomR: zoom(bottomRight!),
                        ),
                        )
                      ]
                    )
                  ),
                ),
              ),
          ),
        ),
      ),
    ),
  );
}
}