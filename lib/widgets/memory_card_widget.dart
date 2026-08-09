import 'dart:math';

import 'package:flutter/material.dart';

import '../models/memory_card_model.dart';

class MemoryCardWidget extends StatefulWidget {
  final MemoryCardModel card;
  final VoidCallback onTap;

  const MemoryCardWidget({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  State<MemoryCardWidget> createState() => _MemoryCardWidgetState();
}

class _MemoryCardWidgetState extends State<MemoryCardWidget>
    with TickerProviderStateMixin {
  late final AnimationController _flipController;
  late final AnimationController _shakeController;

  bool get _isFaceVisible =>
      widget.card.state == CardState.faceUp ||
      widget.card.state == CardState.matched ||
      widget.card.state == CardState.mismatchError;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: _isFaceVisible ? 1 : 0,
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(covariant MemoryCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasFaceVisible = oldWidget.card.state == CardState.faceUp ||
        oldWidget.card.state == CardState.matched ||
        oldWidget.card.state == CardState.mismatchError;

    if (_isFaceVisible != wasFaceVisible) {
      _isFaceVisible ? _flipController.forward() : _flipController.reverse();
    }

    if (widget.card.state == CardState.mismatchError &&
        oldWidget.card.state != CardState.mismatchError) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMatched = widget.card.state == CardState.matched;
    final isError = widget.card.state == CardState.mismatchError;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipController, _shakeController]),
        builder: (context, child) {
          final flipValue = _flipController.value;
          final angle = flipValue * pi;
          final showFront = flipValue > 0.5;

          final shakeOffset = _shakeController.isAnimating
              ? sin(_shakeController.value * pi * 6) * 6
              : 0.0;

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isMatched ? 0.0 : 1.0,
            child: Transform.translate(
              offset: Offset(shakeOffset, 0),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: showFront
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _buildFront(isError),
                      )
                    : _buildBack(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront(bool isError) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? Colors.red : Colors.grey.shade300,
          width: isError ? 3 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(widget.card.fruit.imagePath, fit: BoxFit.contain),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.card.fruit.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Verso do card com a arte "Memória Divertida".
  Widget _buildBack() {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/cards/back_card.png',
        fit: BoxFit.cover,
      ),
    );
  }
}