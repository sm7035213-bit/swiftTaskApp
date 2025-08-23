import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String _baseUrl = 'https://swifttaskapp.onrender.com/ask';

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': message}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['reply'] ?? 'No response';
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Failed to connect to server';
    }
  }
}