import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';

class TranslationService {
  Future<String> sendTranslationRequest(String systemPrompt, String userPrompt) async {
    final response = await http.post(
      Uri.parse(AppConstants.backendUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AppConstants.appToken}",
      },
      body: jsonEncode({
        "systemPrompt": systemPrompt,
        "userPrompt": userPrompt,
      }),
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['result'] ?? "";
    } else {
      final errData = utf8.decode(response.bodyBytes);
      throw "Backend Hatası (${response.statusCode}): $errData";
    }
  }
}