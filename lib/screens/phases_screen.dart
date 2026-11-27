import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../models/difficulty.dart';
import '../utils/responsive.dart';
import '../widgets/background_music.dart';
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
    return BackgroundMusic(
      track: MusicTrack.menu,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8E7),
        appBar: AppBar(
          title: Text('$gameTitle — ${difficulty.label}'),
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
                              MaterialPageRoute(
                                builder: (_) => gameBuilder(difficulty, i),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
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
    final width = responsiveValue(context, phone: 140.0, tablet: 200.0);
    final height = responsiveValue(context, phone: 150.0, tablet: 210.0);
    final numberFontSize = responsiveValue(context, phone: 22.0, tablet: 28.0);
    final titleFontSize = responsiveValue(context, phone: 14.0, tablet: 18.0);

    return GestureDetector(
      onTap: () {
        GameAudio.instance.play(Sfx.tap);
        onTap();
      },
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Fase $number',
              style: TextStyle(
                color: Colors.white,
                fontSize: numberFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: titleFontSize),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
