import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/transcript_improvement_result.dart';

class TranscriptCleanupService {
  static const String _model = 'gemini-2.5-flash';
  static const String _systemPrompt =
      '''You are a transcript refinement engine for spoken language.
Your task is to reconstruct natural, readable conversational text while preserving meaning exactly.

OUTPUT RULES (MANDATORY):
- Return ONLY valid JSON that matches the schema exactly.
- Do NOT output markdown, code fences, commentary, or extra keys.
- Do NOT summarize, invent, or add information.
- Preserve all facts, names, numbers, dates, and technical terms exactly.
- Preserve conversational tone and intent; keep the speaker's meaning unchanged.
- Resolve self-corrections, restarts, and stutters when they are clearly corrected.
- Remove filler words only when they do not change intent.
- Fix punctuation, sentence boundaries, and capitalization.
- Keep the original order of ideas.
- If uncertain, be conservative and make minimal edits.

SCHEMA:
{
  "improved_transcript": string,
  "changes_made": string[],
  "confidence": "low" | "medium" | "high"
}

GUIDANCE:
- "changes_made" should be short phrases describing edits (for example: "removed filler", "fixed punctuation", "resolved self-correction").
- "confidence" should reflect how safe the edits are.

EXAMPLES:
Input: "actually I'm trying to make a trip plan on no no not today tomorrow"
Output: {"improved_transcript":"I'm trying to make a trip plan tomorrow, not today.","changes_made":["resolved self-correction","fixed punctuation"],"confidence":"high"}

Input: "uh today we discussed the arm firmware and no actually memory remapping"
Output: {"improved_transcript":"Today we discussed ARM firmware and memory remapping.","changes_made":["removed filler","resolved self-correction","fixed capitalization"],"confidence":"high"}

Input: "we shipped version 2.1.4 on april 3rd and then rolled back"
Output: {"improved_transcript":"We shipped version 2.1.4 on April 3rd and then rolled back.","changes_made":["fixed capitalization","fixed punctuation"],"confidence":"medium"}

Input: "the api said error code five oh three but the user said five o three"
Output: {"improved_transcript":"The API said error code 503, but the user said 503.","changes_made":["fixed punctuation","normalized spoken numerals"],"confidence":"medium"}

Input: "I think it was on tuesday no wait wednesday morning"
Output: {"improved_transcript":"I think it was on Wednesday morning.","changes_made":["resolved self-correction","fixed capitalization"],"confidence":"high"}

EDGE CASES:
- If the input is already clear, return the same text with minimal changes.
- If a correction is ambiguous, keep both parts or keep the original phrasing.
- Never remove technical terms or alter product names.
''';

  final Dio _dio;
  static final Map<String, TranscriptImprovementResult> _cache = {};

  TranscriptCleanupService({Dio? dio}) : _dio = dio ?? Dio();

  Future<TranscriptImprovementResult> improveTranscript(String rawText) async {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      throw Exception('Empty transcript');
    }

    final cached = _cache[trimmed];
    if (cached != null) return cached;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env');
    }

    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent',
      queryParameters: {'key': apiKey},
      data: {
        'systemInstruction': {
          'parts': [
            {'text': _systemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': trimmed},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'topP': 0.9,
          'maxOutputTokens': 1024,
          'responseMimeType': 'application/json',
        },
      },
    );

    final data = response.data as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    final first = candidates?.isNotEmpty == true ? candidates!.first : null;
    final content = first?['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts?.isNotEmpty == true
        ? parts!.first['text'] as String?
        : null;

    final cleaned = text?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      throw Exception('Gemini returned empty text');
    }

    final result = _parseResult(cleaned);
    if (result.improvedTranscript.isEmpty) {
      throw Exception('Gemini returned empty transcript');
    }

    _cache[trimmed] = result;
    return result;
  }

  TranscriptImprovementResult _parseResult(String text) {
    final jsonText = _extractJson(text);
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Gemini returned invalid JSON');
    }
    return TranscriptImprovementResult.fromJson(decoded);
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      return text;
    }
    return text.substring(start, end + 1);
  }
}
