import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(Dio());
});

class GeminiService {
  final Dio _dio;

  GeminiService(this._dio);

  Future<String> sendMessage({
    required List<Map<String, dynamic>> chatHistory,
    String? base64Pdf,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('Gemini API key is not configured. Please add your GEMINI_API_KEY in the .env file.');
    }

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$apiKey';

    // Format system instruction to model PEERai as an academic peer tutor
    final systemInstruction = {
      'parts': [
        {
          'text': 'You are PEERai, a friendly, supportive, and highly capable academic peer tutor and AI assistant designed for PeerNet. '
              'You help students understand complex concepts, solve coding problems step-by-step, and summarize study materials or PDFs. '
              'Your style is engaging, academic yet conversational, and clear. Format your responses nicely with markdown. '
              'Be concise where possible but thorough when explaining solutions.'
        }
      ]
    };

    // Format chat history contents
    final contents = chatHistory.map((msg) {
      final role = msg['role'] == 'user' ? 'user' : 'model';
      final parts = <Map<String, dynamic>>[
        {'text': msg['text'] as String}
      ];
      return {
        'role': role,
        'parts': parts,
      };
    }).toList();

    // If there is an active PDF attachment in the current user message, append it to the last user message parts
    if (base64Pdf != null && contents.isNotEmpty && contents.last['role'] == 'user') {
      final lastMsgParts = contents.last['parts'] as List;
      lastMsgParts.add({
        'inlineData': {
          'mimeType': 'application/pdf',
          'data': base64Pdf,
        }
      });
    }

    try {
      final response = await _dio.post(
        url,
        data: {
          'systemInstruction': systemInstruction,
          'contents': contents,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map?;
          if (content != null) {
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'] as String? ?? 'No response text received.';
            }
          }
        }
        return 'No content generated.';
      } else {
        throw Exception('API returned status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error']?['message'] ?? e.message;
      throw Exception('Gemini API Error: $errorMsg');
    } catch (e) {
      throw Exception('Failed to contact PEERai: $e');
    }
  }
}
