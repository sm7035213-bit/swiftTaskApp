import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;

Response _cors(Response response) {
  return response.change(headers: {
    ...response.headers,
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  });
}

Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return _cors(Response.ok(''));
      }
      final response = await innerHandler(request);
      return _cors(response);
    };
  };
}

void main() async {
  final env = DotEnv()..load();
  final apiKey = env['OPENAI_API_KEY'];

  final router = Router();

  router.post('/ask', (Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final prompt = data['prompt'];

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "user", "content": prompt}
        ]
      }),
    );

    return Response.ok(
      response.body,
      headers: {'Content-Type': 'application/json'},
    );
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addHandler(router);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Server listening on port ${server.port}');
}