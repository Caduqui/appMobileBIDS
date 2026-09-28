import 'package:flutter/material.dart';

import '../data/completion_phases.dart';
import '../data/memory_phases.dart';
import 'completion_game_screen.dart';
import 'difficulty_screen.dart';
import 'memory_game_screen.dart';

const _memoryTitle = 'Jogo da Memória';
const _completionTitle = 'Complete a Palavra';

class MinigamesScreen extends StatelessWidget {
  const MinigamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: const Text('Escolha um jogo'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          // O Wrap só ocupa a largura do conteúdo; sem esse SizedBox ele
          // ficava encostado na esquerda e o "center" valia só dentro dele.
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 24,
              children: [
                _MinigameCard(
                  title: _memoryTitle,
                  imagePath: 'assets/cards/back_card.png',
                  imageSize: const Size(1011, 1432),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DifficultyScreen(
                          gameTitle: _memoryTitle,
                          phaseTitlesFor: (difficulty) => [
                            for (final phase in kMemoryPhases[difficulty]!) phase.title,
                          ],
                          gameBuilder: (difficulty, phaseIndex) => MemoryGameScreen(
                            difficulty: difficulty,
                            phaseIndex: phaseIndex,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                _MinigameCard(
                  title: _completionTitle,
                  imagePath: 'assets/cards/completePalavra.jpg',
                  imageSize: const Size(1251, 1886),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DifficultyScreen(
                          gameTitle: _completionTitle,
                          phaseTitlesFor: (difficulty) => [
                            for (final phase in kCompletionPhases[difficulty]!) phase.title,
                          ],
                          gameBuilder: (difficulty, phaseIndex) => CompletionGameScreen(
                            difficulty: difficulty,
                            phaseIndex: phaseIndex,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Novos minigames entram aqui como novos _MinigameCard.
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MinigameCard extends StatelessWidget {
  final String title;
  final String imagePath;

  /// Tamanho em pixels do arquivo da imagem. Só a proporção importa: a
  /// miniatura usa a mesma, então nada da arte é cortado.
  final Size imageSize;
  final VoidCallback onTap;

  const _MinigameCard({
    required this.title,
    required this.imagePath,
    required this.imageSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 180,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: imageSize.width / imageSize.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
