import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/subject_provider.dart';
import '../state/theme_provider.dart';
import '../models/history.dart' as mh;
import '../widgets/app_shell.dart';
import 'flashcard_review_screen.dart';

class SubjectOverviewScreen extends StatefulWidget {
  static const routeRoot = '/subject';
  final Subject subject;
  const SubjectOverviewScreen({Key? key, required this.subject}) : super(key: key);

  @override
  State<SubjectOverviewScreen> createState() => _SubjectOverviewScreenState();
}

class _SubjectOverviewScreenState extends State<SubjectOverviewScreen> {
  late Future<List<mh.History>> _futureHistories;

  @override
  void initState() {
    super.initState();
    _loadHistories();
    // Prime Gemini for this subject so it knows to only answer related questions.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final prov = context.read<SubjectProvider>();
        final resp = await prov.primeSubject(widget.subject.id);
        if (resp != null && resp.trim() == 'The Question is not related to Subject') {
          // Show a dialog informing the user that the model signalled off-topic behavior
          if (mounted) {
            showDialog<void>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Model Notice'),
                content: const Text('The Question is not related to Subject'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
                ],
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('primeSubject call failed: $e');
      }
    });
  }

  void _loadHistories() {
    _futureHistories = context.read<SubjectProvider>().fetchHistoriesForSubject(widget.subject.id);
    setState(() {});
  }

  Future<void> _confirmDeleteAndRemove(mh.History h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete flashcard set?'),
        content: Text('Are you sure you want to delete "${h.userPrompt == null || h.userPrompt!.isEmpty ? h.prompt : h.userPrompt!}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await context.read<SubjectProvider>().deleteFlashcardSet(widget.subject.id, h.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Deleted flashcard set'),
            backgroundColor: AppColors.orange600,
          ),
        );
        _loadHistories();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: widget.subject.title,
      subject: widget.subject,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
              ? [AppColors.black, AppColors.grey900]
              : [AppColors.grey50, AppColors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Create new flashcard button with gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.orange500, AppColors.orange700],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange500.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/subject/${widget.subject.id}/new',
                        arguments: widget.subject,
                      ).then((_) => _loadHistories());
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create New Flashcards',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Generate from text, files, or images',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Section header
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.orange500,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Flashcard Sets',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // History list
              Expanded(
                child: FutureBuilder<List<mh.History>>(
                  future: _futureHistories,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange500),
                        ),
                      );
                    }
                    final list = snap.data ?? [];
                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open_outlined,
                              size: 64,
                              color: AppColors.grey400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No flashcard sets yet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.grey600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first set to get started',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final h = list[i];
                        return _HistoryCard(
                          history: h,
                          index: i,
                          onTap: () {
                            final cards = h.cards.asMap().entries.map((e) {
                              final c = e.value;
                              return Flashcard(id: '${h.id}-${e.key}', question: c.question, answer: c.answer);
                            }).toList();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FlashcardReviewScreen(
                                  subject: widget.subject,
                                  cards: cards,
                                  startIndex: 0,
                                ),
                              ),
                            ).then((_) => _loadHistories());
                          },
                          onDelete: () => _confirmDeleteAndRemove(h),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final mh.History history;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.history,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.history;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        child: Card(
          elevation: _isHovered ? 8 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.orange500, AppColors.orange700],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.userPrompt == null || h.userPrompt!.isEmpty ? h.prompt : h.userPrompt!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.style, size: 14, color: AppColors.orange600),
                            const SizedBox(width: 4),
                            Text(
                              '${h.cards.length} cards',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.orange600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.calendar_today, size: 14, color: AppColors.grey500),
                            const SizedBox(width: 4),
                            Text(
                              h.createdAt.toLocal().toString().split('.').first,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete this flashcard set',
                    color: Colors.red,
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}