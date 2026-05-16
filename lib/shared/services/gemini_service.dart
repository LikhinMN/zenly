import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/recording_mode.dart';

class GeminiService {
  final Dio _dio = Dio();

  Future<String?> transform(String rawTranscript, RecordingMode mode) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found');
    }

    final endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemma-4-26b-a4b-it:generateContent?key=$apiKey';

    final body = {
      'contents': [
        {
          'parts': [
            {
              'text': '${mode.prompt}\n\n$rawTranscript',
            },
          ],
        },
      ],
    };

    try {
      final response = await _dio.post(
        endpoint,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: body,
      );

      if (response.statusCode == 200) {
        print(response.data);
        return response.data['candidates'][0]['content']['parts'][0]['text']
            as String?;
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        print(e.response?.data);
      }
      print(e);
    }

    return null;
  }
}
