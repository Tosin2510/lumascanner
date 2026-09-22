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
      final decode = img.decodeImage(imageByte)!;
      final image = widg.MemoryImage(imageByte);
      final format = PdfPageFormat(
        decode.width.toDouble(),
        decode.height.toDouble(),
      );
      pdf.addPage(
        widg.Page(
          pageFormat: format,
          margin: widg.EdgeInsets.zero,
          build: (context) {
            return widg.Center(
              child: widg.Image(image, fit: widg.BoxFit.contain)
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