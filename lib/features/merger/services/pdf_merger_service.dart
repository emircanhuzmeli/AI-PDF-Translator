import 'dart:io';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfMergerService {
  Future<List<int>> mergePdfFiles(List<String> filePaths) async {
    final PdfDocument outputDocument = PdfDocument();

    for (String filePath in filePaths) {
      final File file = File(filePath);
      final List<int> bytes = await file.readAsBytes();
      final PdfDocument inputDocument = PdfDocument(inputBytes: bytes);

      for (int i = 0; i < inputDocument.pages.count; i++) {
        final PdfPage sourcePage = inputDocument.pages[i];
        final PdfPage newPage = outputDocument.pages.add();
        
        newPage.graphics.drawPdfTemplate(
          sourcePage.createTemplate(),
          Offset.zero,
          Size(sourcePage.size.width, sourcePage.size.height),
        );
      }
      inputDocument.dispose();
    }

    final List<int> mergedBytes = await outputDocument.save();
    outputDocument.dispose();
    return mergedBytes;
  }
}