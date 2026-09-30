import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as widg;
import 'package:image/image.dart' as img;

class PdfService {
  Future<String> createdPdf(List<XFile> images) async {
    final pdf = widg.Document();
    for (final singleImage in images) {
      final imageByte = await File(singleImage.path).readAsBytes();
      final decodeImage = img.decodeImage(imageByte)!;
      final imageval = widg.MemoryImage(imageByte);
      final format = PdfPageFormat(
        decodeImage.width.toDouble(),
        decodeImage.height.toDouble(),
      );

      pdf.addPage(
        widg.Page(
          pageFormat: format,
          margin: widg.EdgeInsets.zero,
          build: (context) {
            return widg.Center(
              child: widg.Image(imageval, fit: widg.BoxFit.contain)
            );
          }
        )
      );
    }

// Added this to temporarily store the generated PDF in the app document directory.
    final appDir = await getApplicationDocumentsDirectory();
    final pdfDocsDir = Directory(path.join(appDir.path, 'Documents'));

    if (!await pdfDocsDir.exists()) {
      await pdfDocsDir.create(recursive: true);
    }
    final name = 'pdfdocument${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfPath = path.join(pdfDocsDir.path, name);
    await File(pdfPath).writeAsBytes(await pdf.save());
    return pdfPath;
  }
}