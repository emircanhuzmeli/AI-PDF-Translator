import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_merger_service.dart';

class MergerScreen extends StatefulWidget {
  const MergerScreen({super.key});

  @override
  State<MergerScreen> createState() => _MergerScreenState();
}

class _MergerScreenState extends State<MergerScreen> {
  final PdfMergerService _mergerService = PdfMergerService();
  final List<String> _mergeFilePaths = [];
  String _mergeStatus = "Select PDF files one by one to add them to the queue.";
  bool _isMerging = false;

  Future<void> _addFile() async {
    HapticFeedback.lightImpact();
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _mergeFilePaths.add(result.files.single.path!);
        _mergeStatus = "${_mergeFilePaths.length} PDF files in queue.";
      });
    }
  }

  Future<void> _mergePDFs() async {
    if (_mergeFilePaths.length < 2) return;
    setState(() {
      _isMerging = true;
      _mergeStatus = "Merging PDF files...";
    });

    try {
      List<int> mergedBytes = await _mergerService.mergePdfFiles(_mergeFilePaths);
      String? savePath = await FilePicker.saveFile(dialogTitle: 'Save Merged PDF', fileName: 'merged_document.pdf');

      if (savePath != null) {
        final File outputFile = File(savePath);
        await outputFile.writeAsBytes(mergedBytes);
        setState(() {
          _mergeStatus = "Success! Saved: $savePath";
          _isMerging = false;
        });
        HapticFeedback.heavyImpact();
      } else {
        setState(() => _isMerging = false);
      }
    } catch (e) {
      setState(() {
        _mergeStatus = "Merge error: $e";
        _isMerging = false;
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
          Text(_mergeStatus, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.tealAccent)),
          const SizedBox(height: 10),
          ElevatedButton.icon(onPressed: _isMerging ? null : _addFile, icon: const Icon(Icons.add_circle_outline), label: const Text("Add PDF to Queue")),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFF181818), borderRadius: BorderRadius.circular(10)),
              child: ListView.builder(
                itemCount: _mergeFilePaths.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(child: Text("${index + 1}")),
                    title: Text(_mergeFilePaths[index].split(Platform.pathSeparator).last),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => setState(() => _mergeFilePaths.removeAt(index))),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(onPressed: (_isMerging || _mergeFilePaths.length < 2) ? null : _mergePDFs, icon: const Icon(Icons.merge_type), label: const Text("Merge Queue & Save"), style: ElevatedButton.styleFrom(backgroundColor: Colors.teal)),
        ],
      ),
    );
  }
}