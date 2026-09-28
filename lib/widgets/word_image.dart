import 'package:flutter/material.dart';

import '../models/word_item.dart';

/// Desenha a ilustração de uma palavra: o PNG, se houver, senão o emoji
/// escalado pra caber no espaço disponível.
class WordImage extends StatelessWidget {
  final WordItem item;

  const WordImage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final imagePath = item.imagePath;
    if (imagePath != null) {
      return Image.asset(imagePath, fit: BoxFit.contain);
    }
    return FittedBox(
      fit: BoxFit.contain,
      child: Text(item.emoji!, style: const TextStyle(fontSize: 100)),
    );
  }
}
