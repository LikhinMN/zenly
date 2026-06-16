import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TranscriptionService {
  final Dio _dio = Dio();

  Future<String?> transcribe(String audioFilePath) async {
    try {
      final token = dotenv.env['GROQ_TOKEN'];
      if (token == null) throw Exception('GROQ_TOKEN not found in .env');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFilePath,
          filename: 'audio.m4a',
        ),
        'model': 'whisper-large-v3',
        'response_format': 'json',
        'language': 'en',
      });

      final response = await _dio.post(
        'https://api.groq.com/openai/v1/audio/transcriptions',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: formData,
      );

      debugPrint('Groq Response: ${response.data}');

      if (response.statusCode == 200) {
        return response.data['text'] as String?;
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint('Groq Error body: ${e.response?.data}');
      }
      debugPrint('Transcription error: $e');
      return 'Error: $e';
    }
  }
}
