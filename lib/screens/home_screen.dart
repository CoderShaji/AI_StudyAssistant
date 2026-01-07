import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/subject_provider.dart';
import '../state/theme_provider.dart';
import '../widgets/subject_tile.dart';
import '../widgets/app_shell.dart';
// ...existing code...
import 'ai_history_screen.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';
  const HomeScreen({Key? key}) : super(key: key);

  int _columnsForWidth(double w) {
    if (w >= 1200) return 4;
    if (w >= 900) return 3;
    if (w >= 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectProvider>().subjects;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppShell(
      title: 'My Subjects',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
              ? [AppColors.black, AppColors.grey900]
              : [AppColors.grey50, AppColors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero section with AI generation
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.orange500, AppColors.orange700],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange500.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI-Powered Learning',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Generate flashcards instantly with AI',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiHistoryScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.psychology_outlined),
                        label: const Text('Start with AI'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.orange600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Recent AI chats (generator history)
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: context.read<SubjectProvider>().fetchChatPairsForSubject('ai'),
                      builder: (ctx, snap) {
                        final items = snap.data ?? [];
                        if (items.isEmpty) return const SizedBox.shrink();
                        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          const SizedBox(height: 8),
                          Text('Recent AI sessions', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
                          const SizedBox(height: 8),
                          for (final it in items.take(3))
                            Card(
                              color: Colors.white.withOpacity(0.08),
                              child: ListTile(
                                title: Text(it['prompt'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                                subtitle: Text((it['createdAt'] as DateTime).toLocal().toString().split('.').first, style: const TextStyle(color: Colors.white70)),
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  TextButton(onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AiHistoryScreen()));
                                  }, child: const Text('Open')),
                                  const SizedBox(width: 8),
                                ]),
                              ),
                            ),
                        ]);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section title
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
                    'Your Subjects',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orange100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${subjects.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.orange700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Subjects grid
              Expanded(
                child: subjects.isEmpty
                  ? Center(
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
                            'No subjects yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.grey600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first subject to get started',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(builder: (context, constraints) {
                      final cols = _columnsForWidth(constraints.maxWidth);
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: subjects.length,
                        itemBuilder: (_, i) {
                          final s = subjects[i];
                          return SubjectTile(
                            id: s.id,
                            title: s.title,
                            subtitle: s.subtitle,
                            onTap: () {
                              Navigator.pushNamed(context, '/subject/${s.id}', arguments: s);
                            },
                          );
                        },
                      );
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}