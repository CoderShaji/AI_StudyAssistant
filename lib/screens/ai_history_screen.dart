import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/subject_provider.dart';
import '../pages/chat_page.dart';
import '../state/theme_provider.dart';

class AiHistoryScreen extends StatefulWidget {
  const AiHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends State<AiHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<SubjectProvider>().fetchChatPairsForSubject('ai');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI History'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(title: 'AI Generator', initialMessages: [], subjectId: 'ai'))),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New', style: TextStyle(color: Colors.white)),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [AppColors.grey900, AppColors.grey800] : [AppColors.orange500, AppColors.orange700],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('No AI sessions yet'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (c, i) {
              final it = items[i];
              final created = it['createdAt'] as DateTime?;
              return Card(
                child: ListTile(
                  title: Text(it['prompt'] ?? ''),
                  subtitle: Text(created != null ? created.toLocal().toString().split('.').first : ''),
                  onTap: () {
                    final initial = [
                      ChatMessage(text: it['prompt'] ?? '', isUser: true, time: it['createdAt']),
                      ChatMessage(text: it['answer'] ?? '', isUser: false, time: it['createdAt']),
                    ];
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(title: 'AI Generator', initialMessages: initial, subjectId: 'ai', loadHistory: false)));
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
                        title: const Text('Delete session?'),
                        content: const Text('Delete this saved AI session?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                          ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete')),
                        ],
                      ));
                      if (ok == true) {
                        try {
                          await context.read<SubjectProvider>().deleteChatEntry('ai', it['id']);
                          setState(() => _load());
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                        }
                      }
                    },
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}
