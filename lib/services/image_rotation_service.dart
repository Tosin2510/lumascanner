import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:path/path.dart' as path;


class ImageRotationService{
   Future<String> rotate(String pathToImage, int degrees) =>
      compute(rotateBackgroundOfImage, <Object>[pathToImage, degrees]);
}

String rotateBackgroundOfImage(List<Object> vals) {

  final pathToImage = vals[0] as String;
  final degree = vals[1] as int;

  final decodedImage = image.decodeImage(File(pathToImage).readAsBytesSync())!;
  final rotatedImage = image.copyRotate(image.bakeOrientation(decodedImage), angle: degree);

  final directory = Directory(path.join(path.dirname(pathToImage), 'rotated image'));
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
 
 final name = 'rotated${DateTime.now().microsecondsSinceEpoch}.jpg';
  final rotatedPath = path.join(directory.path, name);
  File(rotatedPath).writeAsBytesSync(image.encodeJpg(rotatedImage, quality: 90));
 
  return rotatedPath;
}