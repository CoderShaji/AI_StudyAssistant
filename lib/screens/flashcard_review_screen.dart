import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../state/subject_provider.dart';
import '../state/theme_provider.dart';
import '../widgets/app_shell.dart';

class FlashcardReviewScreen extends StatefulWidget {
  final Subject subject;
  final List<Flashcard> cards;
  final int startIndex;

  const FlashcardReviewScreen({Key? key, required this.subject, required this.cards, this.startIndex = 0}) : super(key: key);

  @override
  State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen> with SingleTickerProviderStateMixin {
  late int _index;
  bool _showBack = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showBack) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  void _next() {
    if (_index < widget.cards.length - 1) setState(() => _index++);
    if (_showBack) _flip();
  }

  void _prev() {
    if (_index > 0) setState(() => _index--);
    if (_showBack) _flip();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppShell(
      title: widget.subject.title,
      subject: widget.subject,
      child: GestureDetector(
        onHorizontalDragEnd: (d) {
          if (d.primaryVelocity == null) return;
          if (d.primaryVelocity! < 0) _next();
          if (d.primaryVelocity! > 0) _prev();
        },
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
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Card ${_index + 1} of ${widget.cards.length}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.orange500, AppColors.orange700],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(((_index + 1) / widget.cards.length) * 100).toInt()}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (_index + 1) / widget.cards.length,
                        backgroundColor: isDark ? AppColors.grey800 : AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange500),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Flashcard area
              Expanded(
                child: Stack(
                  children: [
                    // Center card (tappable to flip)
                    Center(
                      child: GestureDetector(
                        onTap: _flip,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            final angle = _controller.value * math.pi;
                            final transform = Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle);
                            final isBack = _controller.value > 0.5;
                            final innerTransform = isBack ? (Matrix4.identity()..rotateY(math.pi)) : Matrix4.identity();

                            return Transform(
                              transform: transform,
                              alignment: Alignment.center,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.85,
                                height: MediaQuery.of(context).size.height * 0.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isBack
                                      ? [AppColors.orange500, AppColors.orange700]
                                      : isDark
                                        ? [AppColors.grey800, AppColors.grey700]
                                        : [Colors.white, AppColors.grey50],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isBack
                                        ? AppColors.orange500.withOpacity(0.3)
                                        : Colors.black.withOpacity(0.1),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isBack
                                      ? AppColors.orange600
                                      : isDark ? AppColors.grey700 : AppColors.grey300,
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isBack
                                          ? Colors.white.withOpacity(0.2)
                                          : AppColors.orange100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isBack ? 'ANSWER' : 'QUESTION',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isBack ? Colors.white : AppColors.orange700,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Expanded(
                                      child: Center(
                                        child: Transform(
                                          transform: innerTransform,
                                          alignment: Alignment.center,
                                          child: SingleChildScrollView(
                                            child: Text(
                                              isBack ? card.answer : card.question,
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: isBack ? Colors.white : null,
                                                height: 1.4,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.touch_app_outlined,
                                      size: 20,
                                      color: isBack
                                        ? Colors.white.withOpacity(0.6)
                                        : AppColors.grey500,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Left navigation button
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: _NavButton(
                            icon: Icons.chevron_left,
                            onTap: _prev,
                            enabled: _index > 0,
                          ),
                        ),
                      ),
                    ),

                    // Right navigation button
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: _NavButton(
                            icon: Icons.chevron_right,
                            onTap: _next,
                            enabled: _index < widget.cards.length - 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Known'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.refresh),
                        label: const Text('Review'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: enabled
              ? LinearGradient(
                  colors: [AppColors.orange500, AppColors.orange700],
                )
              : null,
            color: enabled ? null : (isDark ? AppColors.grey800 : AppColors.grey300),
            shape: BoxShape.circle,
            boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.orange500.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          ),
          child: Icon(
            icon,
            size: 28,
            color: enabled ? Colors.white : AppColors.grey500,
          ),
        ),
      ),
    );
  }
}