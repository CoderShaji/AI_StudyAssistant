import 'package:flutter/material.dart';
import '../state/theme_provider.dart';

class ChatInput extends StatefulWidget {
  final void Function(String) onSend;
  final VoidCallback? onUploadTap;
  final String hintText;
  const ChatInput({Key? key, required this.onSend, this.onUploadTap, this.hintText = 'Message'}) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey900 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Upload button with gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.orange500, AppColors.orange700],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange500.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: widget.onUploadTap,
                    icon: const Icon(Icons.add, color: Colors.white),
                    tooltip: 'Upload',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Text field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey800 : AppColors.grey100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? AppColors.grey700 : AppColors.grey300,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(color: AppColors.grey500),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Send button with gradient
              Container(
                decoration: BoxDecoration(
                  gradient: _hasText
                    ? LinearGradient(
                        colors: [AppColors.orange500, AppColors.orange700],
                      )
                    : null,
                  color: _hasText ? null : AppColors.grey400,
                  shape: BoxShape.circle,
                  boxShadow: _hasText
                    ? [
                        BoxShadow(
                          color: AppColors.orange500.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: _hasText ? _handleSend : null,
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    tooltip: 'Send',
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