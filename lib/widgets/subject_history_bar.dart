import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/subject_provider.dart';

class SubjectHistoryBar extends StatelessWidget {
  final String? currentSubjectId;
  const SubjectHistoryBar({Key? key, this.currentSubjectId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubjectProvider>();
    final subjects = provider.subjects;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final s = subjects[i];
          final count = provider.historyFor(s.id).length;
          final selected = currentSubjectId != null && currentSubjectId == s.id;
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/subject/${s.id}', arguments: s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected ? [BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 3))] : null,
                border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha((0.12 * 255).round())),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 14, child: Text(s.title.isNotEmpty ? s.title[0].toUpperCase() : '?')),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      if (count > 0) Text('$count sets', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: subjects.length,
      ),
    );
  }
}
