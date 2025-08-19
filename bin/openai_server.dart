import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;

void main() async {
  final env = DotEnv()..load();
  final apiKey = env['OPENAI_API_KEY'];

  final router = Router();


  router.post('/ask', (Request request) async {
    try {
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

      return Response.ok(response.body, headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      });
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      );
    }
  });


  router.options('/<ignored|.*>', (Request request) {
    return Response.ok('OK', headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
      'Access-Control-Allow-Headers': '*',
    });
  });


  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(headers: {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': '*',
  }))
      .addHandler(router);

  final port = int.parse(Platform.environment['PORT'] ?? '10000');
  //8080
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Server is running on port ${server.port}');
}