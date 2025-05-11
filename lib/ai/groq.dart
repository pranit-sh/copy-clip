import 'dart:convert';
import 'package:copy_clip/ai/groq_params.dart';
import 'package:http/http.dart' as http;

class GroqService {
  final String apiKey;

  GroqService(this.apiKey);

  Future<String> getGroqChatJsonCompletion(List<Map<String, String>> messages) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode({
      'model': groqModel,
      'messages': messages,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['choices'] != null && responseData['choices'].isNotEmpty) {
        return responseData['choices'][0]['message']['content'] ?? '';
      }
    }

    return '';
  }
}