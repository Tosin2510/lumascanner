import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;

class PdfService {
  Future<String> createdPdf(List<XFile> images) async {
    final pdf = pw.Document();
    for (final singleImage in images) {
      final imageByte = await File(singleImage.path).readAsBytes();
      final decode = img.decodeImage(imageByte)!;
      final image = pw.MemoryImage(imageByte);
      final format = PdfPageFormat(
        decode.width.toDouble(),
        decode.height.toDouble(),
      );
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain)
            );
          }
        )
      );
    }

    final appDir = await getApplicationDocumentsDirectory();
    final pdfDocsDir = Directory(path.join(appDir.path, 'Documents'));
    if (!await pdfDocsDir.exists()) {
      await pdfDocsDir.create(recursive: true);
    }
    final name = 'document${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfPath = path.join(pdfDocsDir.path, name);
    await File(pdfPath).writeAsBytes(await pdf.save());
    return pdfPath;
  }
}