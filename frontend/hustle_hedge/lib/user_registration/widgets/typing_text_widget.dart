import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TypingTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDelay;
  final VoidCallback? onComplete;

  const TypingTextWidget({
    super.key,
    required this.text,
    this.style,
    this.charDelay = const Duration(milliseconds: 28),
    this.onComplete,
  });

  @override
  State<TypingTextWidget> createState() => _TypingTextWidgetState();
}

class _TypingTextWidgetState extends State<TypingTextWidget> {
  String _displayed = '';
  Timer? _timer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(TypingTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _displayed = '';
      _charIndex = 0;
      _startTyping();
    }
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.charDelay, (timer) {
      if (_charIndex < widget.text.length) {
        setState(() {
          _displayed += widget.text[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed,
      style: widget.style ??
          const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            height: 1.4,
            fontFamily: AppTheme.fontFamily,
          ),
    );
  }
}

/// Bouncing dots "typing" indicator
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      )..repeat(reverse: true),
    );
    _animations = List.generate(
      3,
      (i) => Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
      ),
    );
    // Stagger
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 130), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}