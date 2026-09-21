import 'dart:io';
import 'dart:ui';
import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;


class PerspectiveTransformService {
  Future<String> transformImage({
    required String imagePath,
    required Offset topLeft,
    required Offset topRight,
    required Offset bottomLeft,
    required Offset bottomRight,
    required Size sizeOfBox
  }) async {
    final valInBytes = await File(imagePath).readAsBytes();
    final decodedImage = image.decodeImage(valInBytes)!;
    final scaleX = decodedImage.width / sizeOfBox.width;
    final scaleY = decodedImage.height / sizeOfBox.height;

    image.Point pointOfScaling(Offset point) => image.Point(point.dx * scaleX, point.dy * scaleY);
    
      final forTLeft = pointOfScaling(topLeft);
      final forTRight = pointOfScaling(topRight);
      final forBLeft = pointOfScaling(bottomLeft);
      final forBRight = pointOfScaling(bottomRight);

      // The rectangle that contains the four points.
      final minvalX = [forTLeft.x, forTRight.x, forBLeft.x, forBRight.x].reduce((a, b) => a < b ? a : b);
      final maxvalX = [forTLeft.x, forTRight.x, forBLeft.x, forBRight.x].reduce((a, b) => a > b ? a : b);
      final minvalY = [forTLeft.y, forTRight.y, forBLeft.y, forBRight.y].reduce((a, b) => a < b ? a : b);
      final maxvalY = [forTLeft.y, forTRight.y, forBLeft.y, forBRight.y].reduce((a, b) => a > b ? a : b);

     final croppedRes = image.copyCrop(
      decodedImage, 
      x: minvalX.round(), 
      y: minvalY.round(), 
      width: (maxvalX - minvalX).round(), 
      height: (maxvalY - minvalY).round(),
    );
    // I am creating a new directory to save the image after performing the perspective transformation.
      final appDir = await getApplicationDocumentsDirectory();
      final perspDocsDir = Directory(path.join(appDir.path, 'persp_docs'));
      if (!await perspDocsDir.exists()) {
        await perspDocsDir.create(recursive: true);
      }

      final name = 'croppedimg${DateTime.now().millisecondsSinceEpoch}.jpg';
      final pathName = path.join(perspDocsDir.path, name);
      await File(pathName).writeAsBytes(image.encodeJpg(croppedRes));

      return pathName;
  }
}