import 'package:flutter/material.dart';
import '../state/theme_provider.dart';

class LongActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  const LongActionButton({Key? key, required this.label, required this.onPressed, this.enabled = true}) : super(key: key);
  
  @override
  State<LongActionButton> createState() => _LongActionButtonState();
}

class _LongActionButtonState extends State<LongActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.enabled ? (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      } : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: widget.enabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.orange500,
                  AppColors.orange700,
                ],
              )
            : null,
          color: widget.enabled ? null : AppColors.grey400,
          borderRadius: BorderRadius.circular(16),
          boxShadow: widget.enabled && !_isPressed
            ? [
                BoxShadow(
                  color: AppColors.orange500.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
        ),
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.label.contains('Generating')) ...[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
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