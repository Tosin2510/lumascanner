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

  Future<void> shareManyDocuments(List<String> pathToPdfDocs) async {
    if (pathToPdfDocs.isEmpty) return;

    final filesIntendedForSharing = <XFile>[];
    for (final path in pathToPdfDocs) {
      filesIntendedForSharing.add(XFile(path));
    }

    await SharePlus.instance.share(
      ShareParams(
        files: filesIntendedForSharing,
        text: 'Share PDF Documents',
      )
    );
  }
}