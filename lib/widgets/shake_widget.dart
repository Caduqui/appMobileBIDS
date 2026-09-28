import 'dart:math';

import 'package:flutter/material.dart';

/// Balança o [child] na horizontal sempre que [triggerKey] muda de valor
/// (mesmo padrão do CelebrationOverlay: um int incremental).
class ShakeWidget extends StatefulWidget {
  final int triggerKey;
  final Widget child;

  const ShakeWidget({super.key, required this.triggerKey, required this.child});

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(covariant ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerKey != oldWidget.triggerKey) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final offset = _controller.isAnimating
            ? sin(_controller.value * pi * 6) * 8
            : 0.0;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
    );
  }
}
