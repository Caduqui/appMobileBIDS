import 'package:flutter/material.dart';

/// Dispara a animação sempre que [triggerKey] muda de valor.
/// Usar um int incremental (em vez de um bool) evita o problema de
/// "acertei dois pares seguidos e o segundo não reanima porque o valor
/// continua true".
class CelebrationOverlay extends StatefulWidget {
  final int triggerKey;

  const CelebrationOverlay({super.key, required this.triggerKey});

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.5, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0)),
    );
  }

  @override
  void didUpdateWidget(covariant CelebrationOverlay oldWidget) {
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
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.value == 0 || _controller.status == AnimationStatus.dismissed) {
            return const SizedBox.shrink();
          }
          return Opacity(
            opacity: _fade.value,
            child: Transform.scale(
              scale: _scale.value,
              child: const Icon(Icons.star_rounded, color: Colors.amber, size: 90),
            ),
          );
        },
      ),
    );
  }
}
