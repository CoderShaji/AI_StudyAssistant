import 'package:flutter/material.dart';
import '../state/subject_provider.dart';

class FlashcardTile extends StatelessWidget {
  final Flashcard card;
  final VoidCallback onTap;
  const FlashcardTile({Key? key, required this.card, required this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        key: Key('flashcard_${card.id}'),
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.secondary, child: Text((card.question.split(' ').first).replaceAll(RegExp(r'[^A-Za-z0-9]'), ''), style: const TextStyle(fontSize: 12))),
        title: Text(card.question, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(card.answer, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text('${card.createdAt.year}-${card.createdAt.month}-${card.createdAt.day}', style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
