import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;
  final String modelId;

  GeminiService({required this.apiKey, this.modelId = 'gemma-3-4b-it'});

  /// Sends [input] to Gemini generateContent endpoint and returns the raw text reply.
  /// This is a simple non-streaming implementation that posts the request body
  /// similar to the bash curl in your snippet.
  Future<String> generateContent(String input) async {
  // Use the non-streaming generateContent endpoint so the response body contains
  // the full generated text instead of streaming token-by-token fragments.
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent?key=$apiKey');

    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": input}
          ]
        }
      ],
      "generationConfig": {}
    };

    final resp = await http.post(url, headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
    if (resp.statusCode != 200) {
      throw Exception('Gemini API error: ${resp.statusCode} ${resp.body}');
    }

    // The beta API returns a JSON structure; try to extract the text in a best-effort way.
    final decoded = jsonDecode(resp.body);

    String? tryExtract(dynamic node) {
      // If node is a Map, try common keys
      if (node is Map) {
        final map = node.cast<String, dynamic>();

        // candidates -> maybe contains content or message
        if (map.containsKey('candidates')) {
          final candidates = map['candidates'];
          if (candidates is List && candidates.isNotEmpty) {
            for (var c in candidates) {
              if (c is Map) {
                if (c.containsKey('content') && c['content'] is String) return c['content'] as String;
                if (c.containsKey('message')) {
                  final msg = c['message'];
                  final found = tryExtract(msg);
                  if (found != null) return found;
                }
              }
            }
          }
        }

        // output could be string or map with text
        if (map.containsKey('output')) {
          final out = map['output'];
          if (out is String) return out;
          final found = tryExtract(out);
          if (found != null) return found;
        }

        // some shapes put text under 'content' or 'text' directly
        if (map.containsKey('content')) {
          final c = map['content'];
          if (c is String) return c;
          final found = tryExtract(c);
          if (found != null) return found;
        }
        if (map.containsKey('text')) {
          final t = map['text'];
          if (t is String) return t;
        }

        // Search common nested patterns
        for (var v in map.values) {
          final found = tryExtract(v);
          if (found != null) return found;
        }
      }

      // If node is a List, iterate and try to extract from each entry
      if (node is List) {
        for (var item in node) {
          final found = tryExtract(item);
          if (found != null) return found;
        }
      }

      // If it's a plain string, return it
      if (node is String) return node;

      return null;
    }

    final extracted = tryExtract(decoded);
    return extracted ?? resp.body;
  }
}
