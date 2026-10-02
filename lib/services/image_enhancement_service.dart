import 'dart:io';
import 'package:path/path.dart' as pth;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;

class ImageEnhancementService {
  Future<String> autoEnhance(String pathToImage) =>
    compute(separateEnhancementFeature, pathToImage);
}


String separateEnhancementFeature(String pathToImage) {
  final bytesVal = File(pathToImage).readAsBytesSync();
  var originalimageVal = image.decodeJpg(bytesVal) ?? image.decodeImage(bytesVal)!;

  originalimageVal = image.bakeOrientation(originalimageVal);

  const maxSide = 2000;
  if (originalimageVal.width >= originalimageVal.height && originalimageVal.width > maxSide) {
    originalimageVal = image.copyResize(originalimageVal, width: maxSide);
  } else if (originalimageVal.height > originalimageVal.width && originalimageVal.height > maxSide) {
    originalimageVal = image.copyResize(originalimageVal, height: maxSide);
  }

  final brightnessCount = List<int>.filled(256, 0);
  for (final value in originalimageVal) {
    brightnessCount[image.getLuminance(value).round().clamp(0, 255)]++;
  }
  final total = originalimageVal.width * originalimageVal.height;
  var valCount = 0;
  var white = 255;
  for (var i = 0; i < 256; i++) {
    valCount += brightnessCount[i];
    if (valCount >= total * 0.99) {
      white = i;
      break;
    }
  }

  if (white >= 235 || white < 120) return pathToImage;

  final scale = 255 / white;
  for (final value in originalimageVal) {
    value.r = (value.r * scale).clamp(0, 255);
    value.g = (value.g * scale).clamp(0, 255);
    value.b = (value.b * scale).clamp(0, 255);
  }

// 
  final directory = Directory(pth.join(pth.dirname(pathToImage), 'enhanced image'));
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }

  final name = 'enhanced${DateTime.now().millisecondsSinceEpoch}.jpg';
    final enhancedPath = pth.join(directory.path, name);
    File(enhancedPath).writeAsBytesSync(image.encodeJpg(originalimageVal, quality: 85));
    
    return enhancedPath;
}