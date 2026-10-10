import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfHelper {
  static String extractTextFromPDF(List<int> bytes) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String combinedText = "";
      int pageCount = document.pages.count;

      for (int i = 0; i < pageCount; i++) {
        try {
          PdfTextExtractor extractor = PdfTextExtractor(document);
          String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
          if (pageText.trim().isNotEmpty) {
            combinedText += "\n--- Page ${i + 1} ---\n$pageText";
          }
        } catch (_) {}
      }
      document.dispose();

      if (combinedText.trim().isNotEmpty) {
        return combinedText;
      }
    } catch (_) {}

    // Safe Byte Recovery Mode
    try {
      String rawContent = utf8.decode(bytes, allowMalformed: true);
      RegExp regExp = RegExp(r'\(([^)]+)\)');
      Iterable<Match> matches = regExp.allMatches(rawContent);
      
      List<String> words = [];
      for (var m in matches) {
        String? word = m.group(1);
        if (word != null && word.trim().isNotEmpty && word.length > 1) {
          words.add(word);
        }
      }

      if (words.isNotEmpty) {
        return "--- Page 1 (Safe Recovery Mode) ---\n${words.join(' ')}";
      }
    } catch (_) {}

    return "";
  }

  static Future<List<int>?> loadUnicodeFontBytes() async {
    try {
      final ByteData fontData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
      return fontData.buffer.asUint8List();
    } catch (_) {
      List<String> fontPaths = [
        '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
        '/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf',
      ];
      for (String path in fontPaths) {
        try {
          final fFile = File(path);
          if (await fFile.exists()) {
            return await fFile.readAsBytes();
          }
        } catch (_) {}
      }
    }
    return null;
  }
}