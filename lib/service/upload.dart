import 'dart:typed_data';
import 'package:http/http.dart' as http;

class UploadService {
  static Future<bool> uploadToPresignedUrl({
    required String url,
    required Uint8List bytes,
  }) async {


    try {
      final res = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "audio/wav",
        },
        body: bytes,
      );


      
      return res.statusCode == 200;
    } catch (e) {
            return false;
    }
  }

}
