import 'dart:convert';
import 'groq.dart';

class Helper {
  final GroqService _groqService;

  Helper(String apiKey) : _groqService = GroqService(apiKey);

  Future<List<Map<String, String>>> generateClipsFromText(String text) async {
    const systemPrompt = """
      You are an intelligent assistant that extracts small but important snippets from long texts. Your task is to identify and return a list of items that users may want to copy and paste quickly.
      These can include (but are not limited to):
      Passwords, Email addresses, API keys or tokens, Terminal or shell commands, URLs, Configuration values, Short and reusable code snippets, File paths or system routes.
      Return the output strictly as a JSON object in the following format:
      {
        "clips": [
          {
            "text": "<the text>"
          }
        ]
      }
      If no such items are found, return an empty array like this:
      {
        "clips": []
      }
    """;

    final userPrompt = "Extract the important snippets from the following text: \n$text";

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ];

    final responseContent = await _groqService.getGroqChatJsonCompletion(messages);
    final jsonData = jsonDecode(responseContent);
    return List<Map<String, String>>.from(jsonData['clips']);
  }

  Future<List<Map<String, String>>> generateNotesFromText(String text) async {
    const systemPrompt = """
      You are an intelligent assistant that summarizes long texts. Your task is to generate a concise summary of the important points from the text and provide a short title for the summary.
      If the text is not summarizable, return an empty array like this:
      {
        "notes": []
      }
      Otherwise, return the output strictly as a JSON object in the following format:
      {
        "notes": [
          {
            "text": "<the summarized text>",
            "title": "<a very short title for the summary>"
          }
        ]
      }
    """;

    final userPrompt = "Summarize the following text and provide a title: \n$text";

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ];

    final responseContent = await _groqService.getGroqChatJsonCompletion(messages);
    final jsonData = jsonDecode(responseContent);
    return List<Map<String, String>>.from(jsonData['notes']);
  }
}