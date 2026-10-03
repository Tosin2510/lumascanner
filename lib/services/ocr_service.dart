import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  
  final textRecogniser = TextRecognizer(script: TextRecognitionScript.latin);

  Future<RecognizedText> processImage(String pathToImage) async {
    final inputImage = InputImage.fromFilePath(pathToImage);

    return textRecogniser.processImage(inputImage);
  }

  void dispose() {
    textRecogniser.close();
  }
}