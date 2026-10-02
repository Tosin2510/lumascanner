import 'package:document_scan/document_scan.dart';
import 'package:flutter/foundation.dart';

class AutomaticEdgeDetection{
  final detector = DocumentDetector();

  Future<DocumentCorners?> detectEdges(String pathToImage) async {
    final inputVal = ScanInput.file(pathToImage);
    final cornerVal = await detector.detect(
      inputVal,
      sensitivity: DetectionSensitivity.strict,
    );

    if (cornerVal == null) {
      debugPrint('No document has been detected');
    } else {
      debugPrint('Document detected with corners'); 
    }
    return cornerVal;
  }
}