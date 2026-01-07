import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/chat_input.dart';
import '../services/gemini_service.dart';
import '../screens/home_screen.dart';
import '../state/theme_provider.dart';
import 'package:provider/provider.dart';
import '../state/subject_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime time;
  ChatMessage({this.id = '', required this.text, required this.isUser, DateTime? time}) : time = time ?? DateTime.now();
}

class ChatPage extends StatefulWidget {
  final String title;
  final List<ChatMessage> initialMessages;
  final String? subjectId;
  final bool loadHistory;
  const ChatPage({Key? key, required this.title, this.initialMessages = const [], this.subjectId, this.loadHistory = true}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late List<ChatMessage> _messages;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.initialMessages);
  if (widget.subjectId != null && widget.loadHistory) {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final provider = context.read<SubjectProvider>();
          final list = await provider.fetchChatForSubject(widget.subjectId!);
          final mapped = list.map((m) => ChatMessage(id: m['id'] ?? '', text: m['text'] ?? '', isUser: m['isUser'] == true, time: m['createdAt'] as DateTime)).toList();
          setState(() {
            _messages = [..._messages, ...mapped];
          });
          _scrollToBottom();
        } catch (e) {
          debugPrint('Failed to load chat history: $e');
        }
      });
    }
  }

  void _addUserMessage(String text) {
    setState(() => _messages.add(ChatMessage(text: text, isUser: true)));
    try {
      if (widget.subjectId != null) context.read<SubjectProvider>().addChatEntry(widget.subjectId!, text, true);
    } catch (_) {}
    final loading = ChatMessage(text: '...', isUser: false);
    setState(() => _messages.add(loading));
    _scrollToBottom();

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          final idx = _messages.indexOf(loading);
          if (idx != -1) _messages[idx] = ChatMessage(text: 'Error: API key not set', isUser: false);
        });
        _scrollToBottom();
      });
      return;
    }

    final svc = GeminiService(apiKey: apiKey);
    svc.generateContent(text).then((reply) async {
      final clean = _sanitize(reply);

      // If the model signals that the question is not related, show a dialog to the user.
      if (clean.trim() == 'The Question is not related to Subject') {
        if (mounted) {
          // Replace the loading placeholder with the message and show a popup.
          setState(() {
            final idx = _messages.indexOf(loading);
            if (idx != -1) _messages[idx] = ChatMessage(text: clean, isUser: false);
          });
          try {
            if (widget.subjectId != null) context.read<SubjectProvider>().addChatEntry(widget.subjectId!, clean, false);
          } catch (_) {}
          await showDialog<void>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Model Notice'),
              content: const Text('The Question is not related to Subject'),
              actions: [
                TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
              ],
            ),
          );
          _scrollToBottom();
          return;
        }
      }

      setState(() {
        final idx = _messages.indexOf(loading);
        if (idx != -1) _messages[idx] = ChatMessage(text: clean, isUser: false);
      });
      try {
        if (widget.subjectId != null) context.read<SubjectProvider>().addChatEntry(widget.subjectId!, clean, false);
      } catch (_) {}
      _scrollToBottom();
    }).catchError((e) {
      setState(() {
        final idx = _messages.indexOf(loading);
        if (idx != -1) _messages[idx] = ChatMessage(text: 'Error: ${e.toString()}', isUser: false);
      });
      _scrollToBottom();
    });
  }

  String _sanitize(String s) {
    var out = s.replaceAll('\u0000', '').replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    return out.trim();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, HomeScreen.routeName, (route) => false),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chat_outlined, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                ? [AppColors.grey900, AppColors.grey800]
                : [AppColors.orange500, AppColors.orange700],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
              ? [AppColors.black, AppColors.grey900]
              : [AppColors.grey50, AppColors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.orange500, AppColors.orange700],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Start a conversation',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ask anything to get started',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[index];
                        return GestureDetector(
                          onLongPress: () async {
                            if (m.id.isNotEmpty && widget.subjectId != null) {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Delete message?'),
                                  content: const Text('Delete this saved message from history?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                                    ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete')),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                try {
                                  await context.read<SubjectProvider>().deleteChatEntry(widget.subjectId!, m.id);
                                  setState(() => _messages.removeAt(index));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                                }
                              }
                            }
                          },
                          child: Align(
                            alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(16),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                gradient: m.isUser ? const LinearGradient(colors: [AppColors.orange500, AppColors.orange700]) : null,
                                color: m.isUser ? null : (isDark ? AppColors.grey800 : Colors.white),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(m.isUser ? 16 : 4),
                                  topRight: Radius.circular(m.isUser ? 4 : 16),
                                  bottomLeft: const Radius.circular(16),
                                  bottomRight: const Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: m.isUser
                                  ? Text(
                                      m.text,
                                      softWrap: true,
                                      maxLines: null,
                                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                                    )
                                  : MarkdownBody(
                                      data: m.text,
                                      selectable: true,
                                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                        p: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white : AppColors.grey900, height: 1.4),
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
              ),

              ChatInput(
                onSend: (text) {
                  if (text.trim().isEmpty) return;
                  _addUserMessage(text.trim());
                  Future.delayed(const Duration(milliseconds: 120), _scrollToBottom);
                },
                onUploadTap: () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: isDark ? AppColors.grey800 : Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.grey400,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _UploadOption(
                            icon: Icons.photo_library_outlined,
                            title: 'Pick Image',
                            subtitle: 'Choose from gallery',
                            color: AppColors.orange500,
                            onTap: () async {
                              Navigator.pop(context);
                              try {
                                final picker = ImagePicker();
                                final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
                                if (img != null) {
                                  setState(() => _messages.add(ChatMessage(text: '[Image attached] ${img.name}', isUser: true)));
                                  _scrollToBottom();
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
                              }
                            },
                          ),
                          _UploadOption(
                            icon: Icons.insert_drive_file_outlined,
                            title: 'Pick File',
                            subtitle: 'PDF, DOCX, XLSX, etc.',
                            color: AppColors.orange600,
                            onTap: () async {
                              Navigator.pop(context);
                              try {
                                final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx', 'doc', 'ppt', 'pptx', 'xlsx']);
                                if (res != null && res.files.isNotEmpty) {
                                  final f = res.files.first;
                                  setState(() => _messages.add(ChatMessage(text: '[File attached] ${f.name}', isUser: true)));
                                  _scrollToBottom();
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File pick failed: $e')));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _UploadOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.grey500),
      onTap: onTap,
    );
  }
}