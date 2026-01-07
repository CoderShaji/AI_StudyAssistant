import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/auth_page.dart';
import '../state/theme_provider.dart';
import 'dart:async';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  late Animation<double> _glowAnimation;

  String _displayText = '';
  int _textIndex = 0;
  bool _showCursor = true;
  bool _isFrontSide = true;
  bool _animationCompleted = false;

  Timer? _textTimer;
  Timer? _cursorTimer;

  final String _frontText = 'What?Why?How?';
  final String _backText = 'Goal.Purpose.Method';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startFrontTextAnimation();

    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (!mounted) return;
      setState(() => _showCursor = !_showCursor);
    });
  }

  void _startFrontTextAnimation() {
    _textTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        if (_textIndex < _frontText.length) {
          _displayText += _frontText[_textIndex];
          _textIndex++;
        } else {
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            _controller.forward().then((_) {
              if (!mounted) return;
              setState(() {
                _isFrontSide = false;
                _displayText = '';
                _textIndex = 0;
              });
              _startBackTextAnimation();
            });
          });
        }
      });
    });
  }

  void _startBackTextAnimation() {
    _textTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {
        if (_textIndex < _backText.length) {
          _displayText += _backText[_textIndex];
          _textIndex++;
        } else {
          timer.cancel();
          setState(() => _animationCompleted = true);
        }
      });
    });
  }

  @override
  void dispose() {
    _textTimer?.cancel();
    _cursorTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.black,
              AppColors.grey900,
              AppColors.black,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated glow effect
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange500.withOpacity(_glowAnimation.value * 0.5),
                          blurRadius: 60 * _glowAnimation.value,
                          spreadRadius: 20 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * math.pi;
                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle);

                    final showingFront = _flipAnimation.value <= 0.5;

                    return Transform(
                      transform: transform,
                      alignment: Alignment.center,
                      child: Container(
                        width: 420,
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              AppColors.grey50,
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.orange500.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.orange500.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Transform(
                              transform: showingFront ? Matrix4.identity() : Matrix4.rotationY(math.pi),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 48,
                                    color: AppColors.orange500,
                                  ),
                                  const SizedBox(height: 16),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: _displayText,
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.grey900,
                                            fontFamily: 'Doto',
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        if (_showCursor)
                                          TextSpan(
                                            text: '|',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.orange500,
                                              fontFamily: 'Doto',
                                            ),
                                          ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 60),
              if (_animationCompleted)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.orange500, AppColors.orange700],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange500.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const AuthPage()),
                            );
                          } else {
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        } catch (e) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthPage()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Let's Start Learning",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Doto',
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
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