import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/history.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save a history document under users/{uid}/histories
  Future<String> saveHistory(History h) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not authenticated');
    // Persist under subjects/{subjectId}/flashcards for the requested app structure
    final ref = _db.collection('users').doc(uid).collection('subjects').doc(h.subjectId).collection('flashcards');
    final docRef = await ref.add({
      'title': h.prompt,
      'userPrompt': h.userPrompt,
      'cards': h.cards.map((c) => c.toMap()).toList(),
      'createdAt': h.toMap()['createdAt'],
    });
    return docRef.id;
  }

  // List histories for a subject
  Future<List<History>> listHistories(String subjectId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
  final ref = _db.collection('users').doc(uid).collection('subjects').doc(subjectId).collection('flashcards');
  final q = await ref.orderBy('createdAt', descending: true).get();
  return q.docs.map((d) => History.fromDoc(d)).toList();
  }

  // Get a single history
  Future<History?> getHistory(String historyId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    // search across subjects is more expensive; assume caller knows subjectId — fallback to scanning user subjects
    final subjects = await _db.collection('users').doc(uid).collection('subjects').get();
    for (final s in subjects.docs) {
      final doc = await _db.collection('users').doc(uid).collection('subjects').doc(s.id).collection('flashcards').doc(historyId).get();
      if (doc.exists) return History.fromDoc(doc, subjectIdOverride: s.id);
    }
    return null;
  }

  // Delete a flashcard set (history) under users/{uid}/subjects/{subjectId}/flashcards/{historyId}
  Future<void> deleteFlashcardSet(String subjectId, String historyId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not authenticated');
    final docRef = _db.collection('users').doc(uid).collection('subjects').doc(subjectId).collection('flashcards').doc(historyId);
    await docRef.delete();
  }

  // Add a chat entry under users/{uid}/chat. Returns the created document id.
  Future<String> addChatEntry(String subjectId, String prompt, String answer) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not authenticated');
    final ref = _db.collection('users').doc(uid).collection('chat');
    final docRef = await ref.add({
      'subjectId': subjectId,
      'prompt': prompt,
      'answer': answer,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Save a single chat message under users/{uid}/chat
  Future<String> saveChatMessage(String subjectId, String text, bool isUser, {DateTime? createdAt}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not authenticated');
    final ref = _db.collection('users').doc(uid).collection('chat');
    final payload = <String, dynamic>{
      'subjectId': subjectId,
      'text': text,
      'isUser': isUser,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
    };
    final docRef = await ref.add(payload);
    return docRef.id;
  }

  // Delete a chat entry by id
  Future<void> deleteChatEntry(String chatId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not authenticated');
    final docRef = _db.collection('users').doc(uid).collection('chat').doc(chatId);
    await docRef.delete();
  }

  // List chat messages for a subject (ordered ascending)
  Future<List<Map<String, dynamic>>> listChatMessages(String subjectId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
  final q = await _db.collection('users').doc(uid).collection('chat').where('subjectId', isEqualTo: subjectId).orderBy('createdAt', descending: false).get();
    return q.docs.map((d) {
      final data = d.data();
      final created = data['createdAt'];
      DateTime ts;
      if (created is Timestamp) ts = created.toDate();
      else if (created is String) ts = DateTime.tryParse(created) ?? DateTime.now();
      else ts = DateTime.now();
      return {
        'id': d.id,
        'subjectId': data['subjectId'],
        'text': data['text'],
        'isUser': data['isUser'] == true,
        'createdAt': ts,
      };
    }).toList();
  }

  // List paired chat histories (prompt/answer pairs) for a subject.
  // Returns documents that contain both 'prompt' and 'answer'. Ordered by createdAt desc.
  Future<List<Map<String, dynamic>>> listChatPairs(String subjectId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final q = await _db.collection('users').doc(uid).collection('chat').where('subjectId', isEqualTo: subjectId).orderBy('createdAt', descending: true).get();
    final out = <Map<String, dynamic>>[];
    for (final d in q.docs) {
      final data = d.data();
      if (data.containsKey('prompt') && data.containsKey('answer')) {
        final created = data['createdAt'];
        DateTime ts;
        if (created is Timestamp) ts = created.toDate();
        else if (created is String) ts = DateTime.tryParse(created) ?? DateTime.now();
        else ts = DateTime.now();
        out.add({'id': d.id, 'prompt': data['prompt'], 'answer': data['answer'], 'createdAt': ts});
      }
    }
    return out;
  }
}
