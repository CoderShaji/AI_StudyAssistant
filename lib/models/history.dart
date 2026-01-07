import 'package:cloud_firestore/cloud_firestore.dart';

class Flashcard {
  final String question;
  final String answer;
  final int order;

  Flashcard({required this.question, required this.answer, required this.order});

  Map<String, dynamic> toMap() => {
        'question': question,
        'answer': answer,
        'order': order,
      };

  static Flashcard fromMap(Map<String, dynamic> m) => Flashcard(
        question: m['question'] ?? '',
        answer: m['answer'] ?? '',
        order: (m['order'] ?? 0) as int,
      );
}

class History {
  final String id;
  final String subjectId;
  final String subjectTitle;
  final String prompt; // fallback to title if present
  final String? userPrompt; // the actual user asked text, prefer to display this in UI
  final int count;
  final DateTime createdAt;
  final String model;
  final String? rawReply;
  final List<Flashcard> cards;

  History({
    required this.id,
    required this.subjectId,
    required this.subjectTitle,
  required this.prompt,
  this.userPrompt,
    required this.count,
    required this.createdAt,
    required this.model,
    this.rawReply,
    required this.cards,
  });

  Map<String, dynamic> toMap() => {
        'subjectId': subjectId,
        'subjectTitle': subjectTitle,
        'prompt': prompt,
  'userPrompt': userPrompt,
        'count': count,
        'createdAt': Timestamp.fromDate(createdAt),
        'model': model,
        'rawReply': rawReply,
        'cards': cards.map((c) => c.toMap()).toList(),
      };

  static History fromDoc(DocumentSnapshot doc, {String? subjectIdOverride}) {
    final data = doc.data() as Map<String, dynamic>;
    final cardsRaw = data['cards'] as List<dynamic>? ?? [];
    final cards = cardsRaw.map((e) => Flashcard.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    // Support docs that use 'title' for the prompt (flashcard sets)
    final promptVal = (data['prompt'] ?? data['title'] ?? '') as String;
    final created = data['createdAt'];
    DateTime createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return History(
      id: doc.id,
      subjectId: data['subjectId'] ?? subjectIdOverride ?? '',
      subjectTitle: data['subjectTitle'] ?? '',
  prompt: promptVal,
  userPrompt: data['userPrompt'] as String?,
  count: ((data['count'] as int?) ?? cards.length),
      createdAt: createdAt,
      model: data['model'] ?? 'unknown',
      rawReply: data['rawReply'],
      cards: cards,
    );
  }
}
