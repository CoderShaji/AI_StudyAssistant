import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/gemini_service.dart';
import '../services/firestore_service.dart';
import '../models/history.dart' as mh;

class Subject {
  final String id;
  final String title;
  final String subtitle;
  final String? asset;
  Subject({required this.id, required this.title, this.subtitle = '', this.asset});
}

class Flashcard {
  final String id;
  final String question;
  final String answer;
  final DateTime createdAt;
  Flashcard({required this.id, required this.question, required this.answer, DateTime? createdAt}) : createdAt = createdAt ?? DateTime.now();
}

class SubjectProvider extends ChangeNotifier {
  final List<Subject> _subjects = [
    Subject(id: 'app', title: 'App Development', subtitle: 'Learn mobile development with Flutter'),
    Subject(id: 'web', title: 'Web Engineering', subtitle: 'Core principles in web Engineering'),
    Subject(id: 'math', title: 'Information Security', subtitle: 'Learn toSecure your Digital Assets'),
    Subject(id: 'prfprc', title: 'Professional Practices', subtitle: 'Ethics in Corporate Life'),
    Subject(id: 'swqe', title: 'Software Quality Engineering', subtitle: 'Ensuring Quality'),
    Subject(id: 'dtm', title: 'Data Mining', subtitle: 'Convert data to Information'),
  ];

  final Map<String, List<Flashcard>> _history = {};
  // Simple per-subject chat history storage. Each entry is a map with text,isUser,time
  final Map<String, List<Map<String, String>>> _chatHistory = {};

  final FirestoreService _fs = FirestoreService();

  List<Subject> get subjects => List.unmodifiable(_subjects);

  List<Flashcard> historyFor(String subjectId) => List.unmodifiable(_history[subjectId] ?? []);

  List<Map<String, String>> chatHistoryFor(String subjectId) => List.unmodifiable(_chatHistory[subjectId] ?? []);

  void addChatEntry(String subjectId, String text, bool isUser, [DateTime? time]) {
    _chatHistory.putIfAbsent(subjectId, () => []);
    _chatHistory[subjectId]!.insert(0, {
      'text': text,
      'isUser': isUser ? '1' : '0',
      'time': (time ?? DateTime.now()).toIso8601String(),
    });
    notifyListeners();
    // Persist message to Firestore as a single chat message
    try {
      _fs.saveChatMessage(subjectId, text, isUser, createdAt: time);
    } catch (e) {
      debugPrint('Failed to persist chat message: $e');
    }
  }

  // Persist a chat entry to Firestore as well
  Future<void> persistChatEntry(String subjectId, String text, bool isUser) async {
    try {
      if (!isUser) {
        // Non-user messages are model answers; store prompt=>answer pairs under user chat
        // We attempt to find the last user message in this subject's chat history to pair with
        final lastUser = _chatHistory[subjectId]?.firstWhere((m) => m['isUser'] == '1', orElse: () => {});
        final prompt = lastUser != null ? (lastUser['text'] ?? '') : '';
        if (prompt.isNotEmpty) {
          await _fs.addChatEntry(subjectId, prompt, text);
        }
      }
    } catch (e) {
      debugPrint('persistChatEntry failed: $e');
    }
  }

  Future<void> deleteChatEntry(String subjectId, String chatId) async {
    try {
      await _fs.deleteChatEntry(chatId);
      // Remove from local cache if present
      final list = _chatHistory[subjectId];
      if (list != null) {
        // local entries don't track doc ids; best-effort: reload from Firestore
        _chatHistory.remove(subjectId);
        // reload from DB
        final remote = await fetchChatForSubject(subjectId);
        _chatHistory[subjectId] = remote.map((m) => {
          'text': m['text']?.toString() ?? '',
          'isUser': (m['isUser'] == true) ? '1' : '0',
          'time': (m['createdAt'] as DateTime).toIso8601String(),
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('deleteChatEntry failed: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchChatForSubject(String subjectId) async {
    try {
      return await _fs.listChatMessages(subjectId);
    } catch (e) {
      debugPrint('fetchChatForSubject error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchChatPairsForSubject(String subjectId) async {
    try {
      return await _fs.listChatPairs(subjectId);
    } catch (e) {
      debugPrint('fetchChatPairsForSubject error: $e');
      return [];
    }
  }

  // Generate flashcards using GeminiService when available; falls back to a mock generator.
  // `source` is the user-provided topic / content. `count` is the exact number of flashcards to produce.
  Future<List<Flashcard>> generateFlashcards(String subjectId, String source, {int count = 5}) async {
    // Minimal guard
    if (count <= 0) count = 1;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
  debugPrint('generateFlashcards: GEMINI_API_KEY missing or empty — falling back to mock generator');
      // Fallback to mock behavior but keep the requested count
      await Future.delayed(const Duration(seconds: 1));
      final cards = List.generate(count, (i) {
        return Flashcard(
          id: '$subjectId-${DateTime.now().millisecondsSinceEpoch}-$i',
          question: 'Q${i + 1} about ${subjectId.toUpperCase()}',
          answer: 'A${i + 1} — derived from provided content (mock).',
        );
      });
      _history.putIfAbsent(subjectId, () => []);
      _history[subjectId] = [...cards, ..._history[subjectId]!];
      notifyListeners();
      return cards;
    }

    // Build strict prompt as requested by the product rules and append user input
    final instruction = '''You are a flashcard generator. Based on the user’s input topic, generate a specific number of short and concise Question/Answer pairs.

Rules to follow strictly:

Generate exactly $count flashcards.

Each flashcard must have:

A Question written clearly in one paragraph.

An Answer written clearly in the next paragraph.

Keep both question and answer very short and to the point (ideal for flashcards).

Do not add extra explanations, numbering, or formatting beyond the plain Question and Answer text.

Only output the flashcards, nothing else. only answer questions related to Computer,Professional Ethics, Quality Engineering ,Information Security 
''';

    final prompt = '$instruction\n$source';

    try {
  debugPrint('generateFlashcards: attempting to generate $count cards for subject $subjectId');
  debugPrint('generateFlashcards: checking GEMINI_API_KEY presence');
      final svc = GeminiService(apiKey: apiKey);
  debugPrint('generateFlashcards: GEMINI_API_KEY present, building prompt (length ${prompt.length})');
      final raw = await svc.generateContent(prompt);
  debugPrint('generateFlashcards: received raw reply of length ${raw.length}');

      // Sanitise control chars
      var clean = raw.replaceAll('\u0000', '').replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '').trim();

      // Heuristic parsing: try multiple strategies to extract distinct question/answer pairs
      final List<Map<String, String>> pairs = [];

      // 1) Break into paragraph blocks (double newline separated)
      final blocks = clean.split(RegExp(r'\r?\n\s*\r?\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      for (final blk in blocks) {
        if (pairs.length >= count) break;

        // 1a) If block contains an explicit 'Answer' marker, split there (case-insensitive)
  final ansMatch = RegExp(r'answer[:\.\)\-\s]*', caseSensitive: false).firstMatch(blk);
        if (ansMatch != null) {
          final q = blk.substring(0, ansMatch.start).trim();
          var a = blk.substring(ansMatch.end).trim();
          if (q.isNotEmpty && a.isNotEmpty) {
            final qclean = _cleanQA(q);
            a = _cleanQA(a);
            a = _stripTrailingQuestion(a);
            pairs.add({'q': qclean, 'a': a});
            continue;
          }
        }

        // 1b) If block has multiple lines, attempt to use first line as question, rest as answer
        final lines = blk.split(RegExp(r'\r?\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (lines.length >= 2) {
          final first = lines.first;
          final rest = lines.sublist(1).join(' ');
          // If first looks like a question or is short, treat as Q and rest as A
          if (first.endsWith('?') || RegExp(r'^(what|who|when|why|how|define|describe|explain)\b', caseSensitive: false).hasMatch(first) || first.length < 120) {
            final qclean = _cleanQA(first);
            var aclean = _cleanQA(rest);
            aclean = _stripTrailingQuestion(aclean);
            pairs.add({'q': qclean, 'a': aclean});
            continue;
          }

          // Otherwise, attempt to pair adjacent lines inside this block (line pairing)
          for (var i = 0; i + 1 < lines.length && pairs.length < count; i += 2) {
            final q = lines[i];
            final a = lines[i + 1];
            if (q.isNotEmpty && a.isNotEmpty) {
              final qclean = _cleanQA(q);
              var aclean = _cleanQA(a);
              aclean = _stripTrailingQuestion(aclean);
              pairs.add({'q': qclean, 'a': aclean});
            }
          }
          if (pairs.length >= count) break;
          continue;
        }

        // 1c) Single-line block: try to split on common separators if it contains both parts
        final single = blk;
        final sepCandidates = [' - ', ' — ', ' – ', ' : ', '\t', ' — ', ' / '];
        var splitDone = false;
        for (final sep in sepCandidates) {
          if (single.contains(sep)) {
            final parts = single.split(sep).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            if (parts.length >= 2) {
              final qclean = _cleanQA(parts[0]);
              var aclean = _cleanQA(parts.sublist(1).join(' '));
              aclean = _stripTrailingQuestion(aclean);
              pairs.add({'q': qclean, 'a': aclean});
              splitDone = true;
              break;
            }
          }
        }
        if (splitDone) continue;

  // 1d) As a last resort for this block, if it contains 'Q' markers (like 'Q1.'), try to extract numbered Q/A pairs
  final numberedMatches = RegExp(r'^(?:\d+\.|Q\d*\.|Q[:\)])\s*(.+?)\s*(?:\r?\n)+\s*(?:A[:\)]|Answer[:\)])\s*(.+)', caseSensitive: false, multiLine: true, dotAll: true);
  final nm = numberedMatches.firstMatch(single);
        if (nm != null && nm.groupCount >= 2) {
          final q = nm.group(1)!.trim();
          var a = nm.group(2)!.trim();
          final qclean = _cleanQA(q);
          a = _cleanQA(a);
          a = _stripTrailingQuestion(a);
          pairs.add({'q': qclean, 'a': a});
          continue;
        }
      }

      // 2) If we still lack pairs, attempt line-level pairing across the whole response
      if (pairs.length < count) {
        final lines = clean.split(RegExp(r'\r?\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        for (var i = 0; i + 1 < lines.length && pairs.length < count; i += 2) {
          final q = lines[i];
          final a = lines[i + 1];
          if (q.isNotEmpty && a.isNotEmpty) {
            final qclean = _cleanQA(q);
            var aclean = _cleanQA(a);
            aclean = _stripTrailingQuestion(aclean);
            pairs.add({'q': qclean, 'a': aclean});
          }
        }
      }

      // 3) Deduplicate and produce Flashcard objects; ensure we return exactly `count` cards
      final List<Flashcard> cards = [];
      for (var p in pairs) {
        if (cards.length >= count) break;
        final q = p['q'] ?? '';
        final a = p['a'] ?? '';
        if (q.isEmpty || a.isEmpty) continue;
        // Avoid near-duplicates
        if (cards.any((c) => c.question == q && c.answer == a)) continue;
        cards.add(Flashcard(id: '$subjectId-${DateTime.now().millisecondsSinceEpoch}-${cards.length}', question: q, answer: a));
      }

      // If still fewer than requested, pad with simple placeholders (so UI always gets exact count)
      while (cards.length < count) {
        final idx = cards.length + 1;
        cards.add(Flashcard(id: '$subjectId-${DateTime.now().millisecondsSinceEpoch}-$idx', question: 'Generated card $idx', answer: 'No answer generated.'));
      }

      final result = cards.take(count).toList();

      // Persist history to Firestore (per-user)
      try {
        final hist = mh.History(
          id: '',
          subjectId: subjectId,
          subjectTitle: subjects.firstWhere((s) => s.id == subjectId, orElse: () => Subject(id: subjectId, title: subjectId)).title,
          // prompt is the full instruction+source sent to Gemini; userPrompt should store only what the user entered
          prompt: prompt,
          userPrompt: source,
          count: count,
          createdAt: DateTime.now(),
          model: 'gemini',
          rawReply: raw,
          cards: result.map((c) => mh.Flashcard(question: c.question, answer: c.answer, order: 0)).toList(),
        );
  await _fs.saveHistory(hist);
        // persist a chat pairing: prompt -> first answer (if available)
        if (result.isNotEmpty) {
          await persistChatEntry(subjectId, result.first.question, true);
          await persistChatEntry(subjectId, result.first.answer, false);
        }
      } catch (e) {
        debugPrint('Failed to save history to Firestore: $e');
      }

      _history.putIfAbsent(subjectId, () => []);
      _history[subjectId] = [...result, ..._history[subjectId]!];
      notifyListeners();
      return result;
    } catch (e, st) {
      debugPrint('generateFlashcards: exception during generation: $e');
      debugPrint('generateFlashcards: stacktrace: $st');
      // On error, fallback to simple mock set of requested count
      await Future.delayed(const Duration(milliseconds: 500));
      final cards = List.generate(count, (i) {
        return Flashcard(
          id: '$subjectId-${DateTime.now().millisecondsSinceEpoch}-$i',
          question: 'Q${i + 1} about ${subjectId.toUpperCase()}',
          answer: 'A${i + 1} — generation failed, fallback.',
        );
      });
      _history.putIfAbsent(subjectId, () => []);
      _history[subjectId] = [...cards, ..._history[subjectId]!];
      notifyListeners();
      return cards;
    }
  }

  /// Send an initial priming prompt to Gemini for a subject so the model
  /// knows it must only answer questions related to the subject.
  /// Returns the raw Gemini reply (or null if unavailable).
  Future<String?> primeSubject(String subjectId) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('primeSubject: GEMINI_API_KEY missing or empty — skipping prime');
      return null;
    }

    final subjectTitle = subjects.firstWhere((s) => s.id == subjectId, orElse: () => Subject(id: subjectId, title: subjectId)).title;

    final prompt = '''You are a flashcard generator that helps in specific subjects. Right now the subject is "$subjectTitle".

After this you will be asked questions and only answer those that are related to the subject otherwise send "The Question is not related to Subject".''';

    try {
      final svc = GeminiService(apiKey: apiKey);
  final raw = await svc.generateContent(prompt);
  return raw.trim();
    } catch (e) {
      debugPrint('primeSubject: error sending prime prompt: $e');
      return null;
    }
  }

  Future<List<mh.History>> fetchHistoriesForSubject(String subjectId) async {
    try {
      final list = await _fs.listHistories(subjectId);
      return list;
    } catch (e) {
      debugPrint('fetchHistoriesForSubject error: $e');
      return [];
    }
  }

  Future<void> deleteFlashcardSet(String subjectId, String historyId) async {
    try {
      await _fs.deleteFlashcardSet(subjectId, historyId);
    } catch (e) {
      debugPrint('deleteFlashcardSet error: $e');
      rethrow;
    }
  }

  void addFlashcardSet(String subjectId, List<Flashcard> cards) {
    _history.putIfAbsent(subjectId, () => []);
    _history[subjectId] = [...cards, ..._history[subjectId]!];
    notifyListeners();
  }

  // Helper to clean up Q/A strings: remove numbering/labels and collapse whitespace
  String _cleanQA(String s) {
  var out = s.trim();
  // Remove code backticks and fences first
  out = out.replaceAll('```', '');
  out = out.replaceAll('`', '');
  // Remove Markdown emphasis markers but keep inner text: **bold**, *italic*, __bold__, _italic_
  out = out.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*', dotAll: true), (m) => m.group(1) ?? '');
  out = out.replaceAllMapped(RegExp(r'__(.*?)__', dotAll: true), (m) => m.group(1) ?? '');
  out = out.replaceAllMapped(RegExp(r'\*(.*?)\*', dotAll: true), (m) => m.group(1) ?? '');
  out = out.replaceAllMapped(RegExp(r'_(.*?)_', dotAll: true), (m) => m.group(1) ?? '');
  // Remove common bullet markers or leading asterisks/dashes
  out = out.replaceAll(RegExp(r'^[\*\-\+]\s*', multiLine: true), '');
  // Remove any remaining stray asterisks or underscores
  out = out.replaceAll('*', '').replaceAll('_', '');
  // Remove common leading labels like '1.' 'Q1.' 'Q:' 'Question:'
  out = out.replaceFirst(RegExp(r'^\s*(?:\d+[\.|\)]\s*|Q\d*[\.|\):]?\s*|Question[:\)\.\s-]*\s*)', caseSensitive: false), '');
  // Remove 'Flashcard' labels like 'Flashcard 1:'
  out = out.replaceFirst(RegExp(r'^(?:Flashcard\s*\d*[:\)\.\-]*\s*)', caseSensitive: false), '');
  // Remove leading 'Answer:' if present
  out = out.replaceFirst(RegExp(r'^(?:Answer[:\)\.\s-]*\s*)', caseSensitive: false), '');
  // Collapse whitespace
  out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
  return out;
  }

  // Remove trailing lines from an answer that look like another question (to avoid Q leaking into A)
  String _stripTrailingQuestion(String a) {
    var lines = a.split(RegExp(r'\r?\n')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    while (lines.isNotEmpty) {
      final last = lines.last;
      // Heuristics: ends with '?', starts with 'Q' or digits + '.' or starts with common interrogatives
      final isQuestionLine = last.endsWith('?') || RegExp(r'^(?:Q\d*\b|\d+\.|what\b|who\b|when\b|why\b|how\b)', caseSensitive: false).hasMatch(last);
      if (isQuestionLine) {
        lines.removeLast();
        continue;
      }
      break;
    }
    return lines.join(' ');
  }
}
