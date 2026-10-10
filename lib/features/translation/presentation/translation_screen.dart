import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/pdf_helper.dart';
import '../services/translation_service.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TranslationService _service = TranslationService();

  String _translateStatus = "Ready. Please select a PDF file.";
  String? _selectedFilePath;
  String? _originalFileName;
  String _translatedText = "";
  String _detectedSourceLang = "English";
  String _targetLang = "Turkish";
  bool _isTranslating = false;

  Future<void> _selectPDF() async {
    HapticFeedback.lightImpact();
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _originalFileName = result.files.single.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
        _translateStatus = "Reading PDF and analyzing source language...";
        _isTranslating = true;
        _detectedSourceLang = "Detecting...";
        _translatedText = "";
      });

      await _detectLanguage(_selectedFilePath!);
    }
  }

  Future<void> _detectLanguage(String filePath) async {
    try {
      final File file = File(filePath);
      final List<int> bytes = await file.readAsBytes();
      String text = PdfHelper.extractTextFromPDF(bytes);

      if (text.trim().isEmpty) {
        setState(() {
          _detectedSourceLang = "English";
          _translateStatus = "Source language defaulted to 'English'.";
          _isTranslating = false;
        });
        return;
      }

      String sys = "You are a precise language detection assistant.";
      String usr = "Identify language and output ONLY language name in English:\n\n${text.substring(0, text.length > 400 ? 400 : text.length)}";

      String detected = await _service.sendTranslationRequest(sys, usr);
      setState(() {
        _detectedSourceLang = detected.trim().isNotEmpty ? detected.trim() : "English";
        _translateStatus = "Source Language: $_detectedSourceLang. Ready to translate.";
        _isTranslating = false;
      });
      HapticFeedback.selectionClick();
    } catch (e) {
      setState(() {
        _detectedSourceLang = "English";
        _translateStatus = "Source language defaulted to 'English'.";
        _isTranslating = false;
      });
    }
  }

  Future<void> _startTranslation() async {
    HapticFeedback.mediumImpact();
    if (_selectedFilePath == null) {
      setState(() => _translateStatus = "Please select a PDF file first!");
      return;
    }

    setState(() {
      _isTranslating = true;
      _translateStatus = "Translating via Secure Backend Service...";
      _translatedText = "";
    });

    try {
      final File file = File(_selectedFilePath!);
      final List<int> bytes = await file.readAsBytes();
      String fullText = PdfHelper.extractTextFromPDF(bytes);

      if (fullText.trim().isEmpty) throw "No readable text content found inside the PDF.";

      String targetEnglishName = AppConstants.supportedLanguages[_targetLang] ?? "Turkish";

      String sysPrompt = "You are a world-class translation engine. Translate into $targetEnglishName.";
      String usrPrompt = "Translate text from '$_detectedSourceLang' to '$_targetLang' ($targetEnglishName):\n\n$fullText";

      String response = await _service.sendTranslationRequest(sysPrompt, usrPrompt);

      setState(() {
        _translatedText = response.trim();
        _translateStatus = "Translation complete! Review preview and save.";
        _isTranslating = false;
      });
      HapticFeedback.heavyImpact();
    } catch (e) {
      setState(() {
        _translateStatus = "Error: $e";
        _isTranslating = false;
      });
    }
  }

  Future<void> _savePDF() async {
    HapticFeedback.lightImpact();
    if (_translatedText.isEmpty) return;

    try {
      setState(() {
        _isTranslating = true;
        _translateStatus = "Compiling Universal Unicode PDF document...";
      });

      List<int>? fontBytes = await PdfHelper.loadUnicodeFontBytes();
      if (fontBytes == null) throw "No suitable TrueType Unicode font found!";

      final PdfFont unicodeFont = PdfTrueTypeFont(fontBytes, 11);
      final PdfDocument newDoc = PdfDocument();
      
      List<String> pages = _translatedText.split(RegExp(r'--- Page \d+ ---'));
      for (var pageContent in pages) {
        if (pageContent.trim().isNotEmpty) {
          final PdfPage page = newDoc.pages.add();
          page.graphics.drawString(
            pageContent.trim(),
            unicodeFont,
            brush: PdfSolidBrush(PdfColor(0, 0, 0)),
            bounds: Rect.fromLTWH(20, 20, page.getClientSize().width - 40, page.getClientSize().height - 40),
            format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.top, wordWrap: PdfWordWrapType.word),
          );
        }
      }

      final List<int> bytes = await newDoc.save();
      newDoc.dispose();

      String suggestedName = "${_originalFileName ?? 'document'}_${_targetLang.toLowerCase()}.pdf";
      String? savePath = await FilePicker.saveFile(dialogTitle: 'Save Translated PDF', fileName: suggestedName);

      if (savePath != null) {
        final File outputFile = File(savePath);
        await outputFile.writeAsBytes(bytes);
        setState(() {
          _translateStatus = "Saved successfully: $savePath";
          _isTranslating = false;
        });
        HapticFeedback.mediumImpact();
      } else {
        setState(() {
          _translateStatus = "Save operation cancelled.";
          _isTranslating = false;
        });
      }
    } catch (e) {
      setState(() {
        _translateStatus = "PDF save error: $e";
        _isTranslating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_translateStatus, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.tealAccent)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(8)),
                  child: Text("Source: $_detectedSourceLang", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _targetLang,
                  decoration: InputDecoration(labelText: "Target", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  items: AppConstants.supportedLanguages.keys.map((lang) => DropdownMenuItem(value: lang, child: Text(lang, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: _isTranslating ? null : (val) => setState(() => _targetLang = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: ElevatedButton.icon(onPressed: _isTranslating ? null : _selectPDF, icon: const Icon(Icons.folder_open), label: const Text("Select PDF"))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(onPressed: _isTranslating ? null : _startTranslation, icon: const Icon(Icons.translate), label: const Text("Translate"), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal))),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF181818), borderRadius: BorderRadius.circular(10)),
              child: SingleChildScrollView(child: SelectableText(_translatedText.isEmpty ? "Preview area..." : _translatedText)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(onPressed: (_isTranslating || _translatedText.isEmpty) ? null : _savePDF, icon: const Icon(Icons.save_alt), label: const Text("Save as PDF"), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange)),
          if (_isTranslating) const LinearProgressIndicator(color: Colors.tealAccent),
        ],
      ),
    );
  }
}
