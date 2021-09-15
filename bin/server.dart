import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:math';

import 'package:functions_framework/functions_framework.dart';

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = params(request, 'message');
  return Response.ok('$message\n');
}
const _mm = '🎁 🎁 🎁 🎁 DartServer  🎁 ';
void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final _handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(_handler, ip, port);
  print('$_mm Server listening on port ${server.port}');
}
@CloudFunction()
GreetingResponse function(GreetingRequest request, RequestContext context) {
  final name = '${request.name} World';
  final response =
  GreetingResponse(salutation: 'Heita', name: name);
  context.logger.info('greetingResponse: ${response.salutation}');
  return response;
}

class GreetingRequest {
  final String name;

  GreetingRequest({required this.name});
}

class GreetingResponse {
  final String salutation;
  final String name;

  GreetingResponse({required this.salutation, required this.name});
}
