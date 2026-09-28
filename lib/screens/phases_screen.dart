import 'package:flutter/material.dart';

import '../models/difficulty.dart';
import 'difficulty_screen.dart';

/// Terceira etapa do fluxo: lista as fases da dificuldade escolhida.
class PhasesScreen extends StatelessWidget {
  final String gameTitle;
  final Difficulty difficulty;
  final List<String> phaseTitles;
  final Widget Function(Difficulty difficulty, int phaseIndex) gameBuilder;

  const PhasesScreen({
    super.key,
    required this.gameTitle,
    required this.difficulty,
    required this.phaseTitles,
    required this.gameBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text('$gameTitle — ${difficulty.label}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          // SizedBox: o Wrap só ocupa a largura do conteúdo; sem ele o
          // "center" valeria só dentro do bloco, encostado na esquerda.
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 24,
              children: [
                for (var i = 0; i < phaseTitles.length; i++)
                  _PhaseCard(
                    number: i + 1,
                    title: phaseTitles[i],
                    color: difficultyColor(difficulty),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => gameBuilder(difficulty, i)),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final int number;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _PhaseCard({
    required this.number,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 150,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Fase $number',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
