import 'package:document_scan/document_scan.dart';
import 'package:flutter/foundation.dart';

class AutomaticEdgeDetection {
  final detector = DocumentDetector();

  Future<DocumentCorners?> detectEdges(String pathToImage) async {
    final inputVal = ScanInput.file(pathToImage);

    for (final sensitivity in [
      DetectionSensitivity.strict,
      DetectionSensitivity.balanced,
    ]) {
      
      final value = await detector.detect(inputVal, sensitivity: sensitivity);

      if (value != null) {
        debugPrint('Detected at $sensitivity level');
        return value;
      }
    }

    debugPrint('No document detected at any sensitivity level');
    return null;
  }
}