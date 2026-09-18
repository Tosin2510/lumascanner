import 'package:share_plus/share_plus.dart';

class ExportService {
  Future<void> shareDocument(String pdfPath) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(pdfPath)],
        text: 'Share PDF Document',
      )
    );
  }
}