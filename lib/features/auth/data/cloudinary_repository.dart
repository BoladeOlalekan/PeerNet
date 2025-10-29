import 'dart:io';
import 'package:dio/dio.dart';

class CloudinaryRepository {
  final Dio _dio = Dio();

  final String cloudName = 'dewaejnbk';
  final String uploadPreset = 'PeerNet';

  Future<String> uploadUserImage(File imageFile) async {
    final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path),
      'upload_preset': uploadPreset,
    });

    final response = await _dio.post(url, data: formData);

    if (response.statusCode == 200) {
      return response.data['secure_url']; // 👈 URL you’ll save in Supabase
    } else {
      throw Exception('Cloudinary upload failed: ${response.statusMessage}');
    }
  }
}
