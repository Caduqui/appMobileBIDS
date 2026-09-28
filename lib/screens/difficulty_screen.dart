import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import 'phases_screen.dart';

Color difficultyColor(Difficulty difficulty) => switch (difficulty) {
      Difficulty.easy => Colors.green,
      Difficulty.medium => Colors.orange,
      Difficulty.hard => Colors.red,
    };

/// Segunda etapa do fluxo: depois de escolher o jogo, escolhe a dificuldade.
/// Serve a qualquer minigame — quem chama diz como listar as fases de cada
/// dificuldade e qual tela abrir quando uma fase é escolhida.
class DifficultyScreen extends StatelessWidget {
  final String gameTitle;
  final List<String> Function(Difficulty difficulty) phaseTitlesFor;
  final Widget Function(Difficulty difficulty, int phaseIndex) gameBuilder;

  const DifficultyScreen({
    super.key,
    required this.gameTitle,
    required this.phaseTitlesFor,
    required this.gameBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text(gameTitle),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Escolha a dificuldade',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                for (final difficulty in Difficulty.values) ...[
                  _DifficultyButton(
                    difficulty: difficulty,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PhasesScreen(
                            gameTitle: gameTitle,
                            difficulty: difficulty,
                            phaseTitles: phaseTitlesFor(difficulty),
                            gameBuilder: gameBuilder,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final Difficulty difficulty;
  final VoidCallback onTap;

  const _DifficultyButton({required this.difficulty, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: difficultyColor(difficulty),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Text(
          difficulty.label,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
