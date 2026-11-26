import 'package:flutter/material.dart';

import '../data/completion_phases.dart';
import '../data/letter_phases.dart';
import '../data/memory_phases.dart';
import '../utils/responsive.dart';
import '../widgets/minigame_art.dart';
import 'completion_game_screen.dart';
import 'difficulty_screen.dart';
import 'letter_sounds_screen.dart';
import 'memory_game_screen.dart';

const _memoryTitle = 'Jogo da Memória';
const _completionTitle = 'Complete a Palavra';
const _letterSoundsTitle = 'Sons das Letras';

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
          child: Center(
            // Limite de largura pra num tablet em paisagem os cards não
            // ficarem espalhados longe um do outro na tela toda.
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth(context)),
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
                      art: MinigameArtKind.memory,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DifficultyScreen(
                              gameTitle: _memoryTitle,
                              phaseTitlesFor: (difficulty) => [
                                for (final phase in kMemoryPhases[difficulty]!)
                                  phase.title,
                              ],
                              gameBuilder: (difficulty, phaseIndex) =>
                                  MemoryGameScreen(
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
                      art: MinigameArtKind.completion,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DifficultyScreen(
                              gameTitle: _completionTitle,
                              phaseTitlesFor: (difficulty) => [
                                for (final phase
                                    in kCompletionPhases[difficulty]!)
                                  phase.title,
                              ],
                              gameBuilder: (difficulty, phaseIndex) =>
                                  CompletionGameScreen(
                                    difficulty: difficulty,
                                    phaseIndex: phaseIndex,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                    _MinigameCard(
                      title: _letterSoundsTitle,
                      art: MinigameArtKind.letterSounds,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DifficultyScreen(
                              gameTitle: _letterSoundsTitle,
                              phaseTitlesFor: (difficulty) => [
                                for (final phase in kLetterPhases[difficulty]!)
                                  phase.title,
                              ],
                              gameBuilder: (difficulty, phaseIndex) =>
                                  LetterSoundsScreen(
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
        ),
      ),
    );
  }
}

class _MinigameCard extends StatelessWidget {
  final String title;
  final MinigameArtKind art;
  final VoidCallback onTap;

  const _MinigameCard({
    required this.title,
    required this.art,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = responsiveValue(context, phone: 180.0, tablet: 260.0);
    final fontSize = responsiveValue(context, phone: 16.0, tablet: 20.0);
    // Mesmo arredondamento que a arte usa no próprio desenho (30 de 300),
    // pra borda clara de dentro acompanhar a borda do card.
    final radius = BorderRadius.circular(width * 0.1);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x29000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipRRect(borderRadius: radius, child: MinigameArt(art)),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
            ),
          ],
        ),
      ),
    );
  }
}
