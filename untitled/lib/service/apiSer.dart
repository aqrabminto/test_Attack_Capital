import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = "http://80.225.222.33:8080"; // Android emulator
  static String? jwt;

  static Future<void> login() async {
    final url = Uri.parse("$baseUrl/auth/mock-login");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": "doctor@example.com"}),
    );

    final data = jsonDecode(res.body);
        jwt = data["token"];
  }

  static Map<String, String> _authHeaders() =>
      {"Authorization": "Bearer $jwt", "Content-Type": "application/json"};

  static Future<String> createSession({
    required String patientId,
  }) async {
    final url = Uri.parse("$baseUrl/v1/upload-session");
    final res = await http.post(
      url,
      headers: _authHeaders(),
      body: jsonEncode({
        "patientId": patientId,
        "userId": "user_123",
        "patientName": "John Doe",
      }),
    );

    return jsonDecode(res.body)["id"];
  }

  static Future<Map<String, dynamic>> getPresignedUrl({
    required String sessionId,
    required int chunkNumber,
  }) async {
            final url = Uri.parse("$baseUrl/v1/get-presigned-url");

    final res = await http.post(
      url,
      headers: _authHeaders(),
      body: jsonEncode({
        "sessionId": sessionId,
        "chunkNumber": chunkNumber,
        "mimeType": "audio/wav"
      }),
    );

    return jsonDecode(res.body);
  }





  static Future<void> notifyChunk({
    required String sessionId,
    required int chunk,
    required String gcsPath,
    required String publicUrl,
    required bool isLast,
  }) async {
    final url = Uri.parse("$baseUrl/v1/notify-chunk-uploaded");

   final res= await http.post(
      url,
      headers: _authHeaders(),
      body: jsonEncode({
        "sessionId": sessionId,
        "chunkNumber": chunk,
        "gcsPath": gcsPath,
        "publicUrl": publicUrl,
        "isLast": isLast,
      }),
    );
     }
}
