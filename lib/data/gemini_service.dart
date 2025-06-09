import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;

  GeminiService(this.apiKey);

  Future<String?> refineGoal(String goalText) async {
    final prompt =
        '''다음 학습 또는 작업 목표를 SMART(Specific, Measurable, Achievable, Relevant, Time-bound) 원칙에 따라 더 구체적이고 실행 가능하게 다듬어 주세요.\n사용자 목표: "$goalText"\n제안된 목표: ''';

    final response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Gemini API 오류: ${response.statusCode}');
    }
  }

  Future<String?> getBreakIdea() async {
    final prompt = '짧고 상쾌하며 생산적인 휴식 활동 아이디어를 한 문장으로 제안해주세요. (예: 5분간 스트레칭하기)';

    final response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return result['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Gemini API 오류: ${response.statusCode}');
    }
  }
}
