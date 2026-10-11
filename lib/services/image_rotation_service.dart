import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:path/path.dart' as path;

class ImageRotationService {

  Future<(String, int, int)> rotateBasedOnImgSize(String pathToImage, int valueIndegrees) async {
    final value = await compute(
      rotateBackgroundOfImage,
      <Object>[pathToImage, valueIndegrees],
    );
    return (value[0] as String, value[1] as int, value[2] as int);
  }

  Future<String> rotate(String pathToImage, int valuesIndegrees) async {
    final value = await rotateBasedOnImgSize(pathToImage, valuesIndegrees);
    return value.$1;
  }

}

List<Object> rotateBackgroundOfImage(List<Object> args) {
  final pathToImage = args[0] as String;
  final degree = args[1] as int;

  var decodedImage = image.decodeImage(File(pathToImage).readAsBytesSync())!;
  decodedImage = image.bakeOrientation(decodedImage);

// I added this so that the image size is reduced before rotation to make it faster.

  const maximumSide = 2000;
  if (decodedImage.width >= decodedImage.height && decodedImage.width > maximumSide) {
    decodedImage = image.copyResize(decodedImage, width: maximumSide);
  } else if (decodedImage.height > decodedImage.width && decodedImage.height > maximumSide) {
    decodedImage = image.copyResize(decodedImage, height: maximumSide);
  }

  final rotated = image.copyRotate(decodedImage, angle: degree);

  final directory = Directory(path.join(path.dirname(pathToImage), 'rotated image'));
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }

  final name = 'rotated${DateTime.now().microsecondsSinceEpoch}.jpg';
  final rotatedPath = path.join(directory.path, name);
  File(rotatedPath).writeAsBytesSync(image.encodeJpg(rotated, quality: 85));

  return <Object>[rotatedPath, rotated.width, rotated.height];
}
