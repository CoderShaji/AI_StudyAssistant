import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/subject_provider.dart';
import '../models/history.dart' as mh;
import '../screens/flashcard_review_screen.dart';

class RecentFlashcards extends StatelessWidget {
  final String? subjectId;
  const RecentFlashcards({Key? key, this.subjectId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  // Use real histories when subjectId is provided, otherwise show example sets
  final provider = Provider.of<SubjectProvider>(context, listen: false);
  // items are built below depending on subjectId

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Flashcards', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            // Grid of cards: 3 per row on wide screens, responsive shrink on narrow screens
            LayoutBuilder(builder: (context, constraints) {
              // Calculate item width for 3 columns with spacing
              final crossAxisCount = 3;
              final spacing = 12.0;
              final totalSpacing = spacing * (crossAxisCount - 1);
              final itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
              final itemHeight = 120.0;

              if (subjectId == null) {
                final items = List.generate(9, (i) => {
                  'title': 'Sample Set ${i + 1}',
                  'subtitle': 'Source: ${i % 3 == 0 ? 'PDF' : i % 3 == 1 ? 'Prompt' : 'Image'}'
                });
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: items.map((data) {
                    final idx = items.indexOf(data);
                    return _FlashcardItem(
                      width: itemWidth.clamp(120.0, constraints.maxWidth),
                      height: itemHeight,
                      index: idx,
                      title: data['title'] ?? '',
                      subtitle: data['subtitle'] ?? '',
                      onTap: () {
                        final title = '${data['title']}';
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(leading: IconButton(icon: const Icon(Icons.home), tooltip: 'Home', onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false)), title: Text(title)), body: Center(child: Text('${data['subtitle']}')))));
                      },
                    );
                  }).toList(),
                );
              }

              // When subjectId is provided, fetch grouped histories
              return FutureBuilder<List<mh.History>>(
                future: provider.fetchHistoriesForSubject(subjectId!),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final list = snap.data ?? [];
                  if (list.isEmpty) return const Text('No recent histories');
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: list.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final h = entry.value;
                      final title = (h.userPrompt != null && h.userPrompt!.isNotEmpty) ? h.userPrompt!.split('\n').first : (h.prompt).split('\n').first;
                      final subtitle = '${h.cards.length} cards';
                      return _FlashcardItem(
                        width: itemWidth.clamp(120.0, constraints.maxWidth),
                        height: itemHeight,
                        index: idx,
                        title: title,
                        subtitle: subtitle,
                        onTap: () {
                          final cards = h.cards.asMap().entries.map((e) {
                            final c = e.value;
                            return Flashcard(id: '${h.id}-${e.key}', question: c.question, answer: c.answer);
                          }).toList();
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => FlashcardReviewScreen(subject: provider.subjects.firstWhere((s) => s.id == subjectId!), cards: cards, startIndex: 0)));
                        },
                      );
                    }).toList(),
                  );
                },
              );
            })
          ],
        ),
      ),
    );
  }
}

class _FlashcardItem extends StatefulWidget {
  final double width;
  final double height;
  final int index;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FlashcardItem({required this.width, required this.height, required this.index, required this.title, required this.subtitle, required this.onTap});

  @override
  State<_FlashcardItem> createState() => _FlashcardItemState();
}

class _FlashcardItemState extends State<_FlashcardItem> {
  bool _hover = false;
  bool _pressed = false;

  void _setHover(bool v) => setState(() => _hover = v);

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final elevation = _pressed ? 2.0 : (_hover ? 10.0 : 6.0);
    final yOffset = _pressed ? 1.0 : (_hover ? -6.0 : 0.0);

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) { _setPressed(false); widget.onTap(); },
        onTapCancel: () => _setPressed(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: widget.width,
          height: widget.height,
          transform: Matrix4.translationValues(0, yOffset, 0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.12 * 255).round()), blurRadius: elevation, offset: Offset(0, elevation / 2))],
            border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha((0.28 * 255).round())),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 18, child: Text('${widget.index + 1}')),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                ],
              ),
              const Spacer(),
              Text(widget.subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
