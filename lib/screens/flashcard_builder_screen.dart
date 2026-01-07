import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../state/subject_provider.dart';
import '../state/theme_provider.dart';
import '../widgets/long_action_button.dart';
import '../pages/chat_page.dart';
import '../widgets/app_shell.dart';

enum BuilderMode { flashcard, explain }

enum InputType { text, file, image, youtube }

class FlashcardBuilderScreen extends StatefulWidget {
  final Subject subject;
  const FlashcardBuilderScreen({Key? key, required this.subject}) : super(key: key);
  @override
  State<FlashcardBuilderScreen> createState() => _FlashcardBuilderScreenState();
}

class _FlashcardBuilderScreenState extends State<FlashcardBuilderScreen> {
  BuilderMode _mode = BuilderMode.flashcard;
  InputType _input = InputType.text;
  final TextEditingController _textController = TextEditingController();
  bool _hasContent = false;
  bool _isGenerating = false;
  int _count = 5;
  PlatformFile? _selectedFile;
  XFile? _selectedImage;

  void _onContentChanged() {
    setState(() {
      _hasContent = _textController.text.trim().isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onContentChanged);
    _textController.dispose();
    super.dispose();
  }

  void _generate() async {
    if (_mode == BuilderMode.explain) {
      // Navigate to chat (reuse existing ChatPage). Pass existing chat history for this subject.
      final provider = context.read<SubjectProvider>();
      final raw = provider.chatHistoryFor(widget.subject.id);
      final initial = raw.map((m) => ChatMessage(text: m['text'] ?? '', isUser: (m['isUser'] ?? '0') == '1', time: DateTime.tryParse(m['time'] ?? '') )).toList();
  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(title: '${widget.subject.title} — Explain', initialMessages: initial, subjectId: widget.subject.id)));
      return;
    }

    setState(() => _isGenerating = true);
    // Call provider generator (mock)
  final provider = context.read<SubjectProvider>();
  final cards = await provider.generateFlashcards(widget.subject.id, _textController.text, count: _count);
    setState(() => _isGenerating = false);
    // Navigate to review with generated cards (pass index 0)
    Navigator.pushNamed(context, '/subject/${widget.subject.id}/review/${cards.first.id}', arguments: {'subject': widget.subject, 'cards': cards});
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx', 'doc', 'ppt', 'pptx', 'xlsx']);
    if (res == null) return;
    setState(() {
      _selectedFile = res.files.first;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1080, imageQuality: 85);
    if (img == null) return;
    setState(() {
      _selectedImage = img;
    });
  }

  bool get _supportsDragDrop {
    // Allow drag & drop on web and desktop platforms only
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Widget _buildInputArea() {
    switch (_input) {
      case InputType.text:
        return TextField(
          controller: _textController,
          maxLines: 12,
          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Paste text here'),
        );
      case InputType.file:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Large drop / pick area for documents
            _supportsDragDrop
                ? DropTarget(
                    onDragDone: (detail) async {
                      final paths = detail.files.map((f) => f.path).toList();
                      // filter and pick first matching document
                      for (final p in paths) {
                        final lower = p.toLowerCase();
                        if (lower.endsWith('.pdf') || lower.endsWith('.docx') || lower.endsWith('.doc') || lower.endsWith('.ppt') || lower.endsWith('.pptx') || lower.endsWith('.xlsx')) {
                          setState(() => _selectedFile = PlatformFile(name: p.split(Platform.pathSeparator).last, size: 0, path: p));
                          return;
                        }
                      }
                    },
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text(_selectedFile == null ? 'Drop document here (pdf, docx, pptx, xlsx)' : 'Selected: ${_selectedFile!.name}')),
                    ),
                  )
                : InkWell(
                    onTap: _pickFile,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text(_selectedFile == null ? 'Tap to choose document (pdf, docx, pptx, xlsx)' : 'Selected: ${_selectedFile!.name}')),
                    ),
                  ),
            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: _pickFile, icon: const Icon(Icons.insert_drive_file), label: const Text('Choose file'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange500, foregroundColor: Colors.white)),
          ],
        );
      case InputType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Large drop / pick area for images
            _supportsDragDrop
                ? DropTarget(
                    onDragDone: (detail) async {
                      final paths = detail.files.map((f) => f.path).toList();
                      for (final p in paths) {
                        final lower = p.toLowerCase();
                        if (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.gif')) {
                          setState(() => _selectedImage = XFile(p));
                          return;
                        }
                      }
                    },
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: _selectedImage == null ? const Text('Drop image here') : Image.file(File(_selectedImage!.path), fit: BoxFit.contain)),
                    ),
                  )
                : InkWell(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outline), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: _selectedImage == null ? const Text('Tap to pick image') : Image.file(File(_selectedImage!.path), fit: BoxFit.contain)),
                    ),
                  ),
            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo), label: const Text('Pick image'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange500, foregroundColor: Colors.white)),
          ],
        );
      case InputType.youtube:
        return TextField(decoration: const InputDecoration(border: InputBorder.none, hintText: 'Paste a YouTube link'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Create Flashcards',
      subject: widget.subject,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // content starts here
            ToggleButtons(
              isSelected: [_mode == BuilderMode.flashcard, _mode == BuilderMode.explain],
              onPressed: (i) => setState(() => _mode = i == 0 ? BuilderMode.flashcard : BuilderMode.explain),
              borderRadius: BorderRadius.circular(8),
              fillColor: AppColors.orange500.withOpacity(0.18),
              selectedColor: Colors.white,
              color: AppColors.orange600,
              borderColor: AppColors.orange500,
              selectedBorderColor: AppColors.orange600,
              children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Flashcard')), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Explain with AI'))],
            ),
            const SizedBox(height: 12),
            if (_mode == BuilderMode.flashcard) ...[
              // Long selector for input types
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: InputType.values.map((t) {
                  final idx = InputType.values.indexOf(t);
                  final label = ['Text', 'File', 'Image', 'YouTube'][idx];
                  final sel = _input == t;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton(
                        onPressed: () => setState(() => _input = t),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sel ? AppColors.orange500 : AppColors.grey50,
                          foregroundColor: sel ? Colors.white : AppColors.grey900,
                        ),
                        child: Text(label),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                      Expanded(child: _buildInputArea()),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.insert_drive_file),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_selectedFile!.name)),
                          TextButton(onPressed: () => setState(() => _selectedFile = null), style: TextButton.styleFrom(foregroundColor: AppColors.orange600), child: const Text('Remove'))
                        ])
                      ],
                      if (_selectedImage != null) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          Image.network(_selectedImage!.path, width: 72, height: 72, fit: BoxFit.cover),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_selectedImage!.name)),
                          TextButton(onPressed: () => setState(() => _selectedImage = null), style: TextButton.styleFrom(foregroundColor: AppColors.orange600), child: const Text('Remove'))
                        ])
                      ],
                    ])),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 8),
              // count selector
              Row(
                children: [
                  const Text('Count:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _count,
                    style: TextStyle(color: AppColors.orange600),
                    items: List.generate(10, (i) => i + 1).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                    onChanged: (v) => setState(() => _count = v ?? 5),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 4),
              // single-purpose DropTargets are shown inside each input type above
              LongActionButton(label: _isGenerating ? 'Generating...' : 'Generate flashcards', enabled: !_isGenerating && _hasContent, onPressed: _generate),
            ] else ...[
              // Explain with AI selected - show recent chat preview and button to open full chat
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Explain with AI', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('Recent conversation', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Builder(builder: (ctx) {
                      final provider = context.read<SubjectProvider>();
                      final hist = provider.chatHistoryFor(widget.subject.id);
                      if (hist.isEmpty) return const Text('No chat history yet');
                      final preview = hist.take(5).map((m) => '${m['isUser']=='1' ? 'You' : 'AI'}: ${m['text']}').toList();
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        for (final line in preview) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(line, maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ]);
                    }),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      TextButton(onPressed: () {
                        final provider = context.read<SubjectProvider>();
                        final raw = provider.chatHistoryFor(widget.subject.id);
                        final initial = raw.map((m) => ChatMessage(text: m['text'] ?? '', isUser: (m['isUser'] ?? '0') == '1', time: DateTime.tryParse(m['time'] ?? ''))).toList();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(title: '${widget.subject.title} — Explain', initialMessages: initial, subjectId: widget.subject.id)));
                      }, style: TextButton.styleFrom(foregroundColor: AppColors.orange600), child: const Text('Open Chat')),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(title: '${widget.subject.title} — Explain', initialMessages: const [], subjectId: widget.subject.id))), style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange500, foregroundColor: Colors.white), child: const Text('Start New')),
                    ])
                  ]),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}

