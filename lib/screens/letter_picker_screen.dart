import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../data/letter_phases.dart';
import '../utils/responsive.dart';
import '../widgets/background_music.dart';
import 'letter_sounds_screen.dart';

/// Menu do Sons das Letras: o alfabeto inteiro numa tela só, e tocar numa
/// letra abre o jogo dela. Diferente dos outros jogos, não passa por
/// `DifficultyScreen`/`PhasesScreen`: o usuário achou que não faz sentido o
/// alfabeto ter dificuldade.
class LetterPickerScreen extends StatelessWidget {
  const LetterPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gap = responsiveValue(context, phone: 12.0, tablet: 16.0);
    final maxTile = responsiveValue(context, phone: 96.0, tablet: 140.0);
    const minTile = 64.0;
    const padding = 16.0;

    return BackgroundMusic(
      track: MusicTrack.menu,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8E7),
        appBar: AppBar(
          title: const Text('Sons das Letras'),
          backgroundColor: kLetterSoundsColor,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  math.min(constraints.maxWidth - 2 * padding, maxContentWidth(context));
              final height = constraints.maxHeight - 2 * padding;
              // O maior botão com que as 26 letras cabem na tela sem rolar:
              // criança pequena não sabe que dá pra rolar, e uma letra
              // escondida embaixo "não existe". Só numa tela minúscula o
              // tamanho mínimo vence e a tela rola.
              // floor: sem ele, um arredondamento de ponto flutuante podia mandar
              // o último botão de uma linha pra linha de baixo.
              final tile =
                  _fittingTileSize(width, height, gap).floorToDouble().clamp(minTile, maxTile);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(padding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth(context)),
                    // SizedBox: o Wrap só ocupa a largura do conteúdo; sem ele o
                    // "center" valeria só dentro do bloco, encostado na esquerda.
                    child: SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (var i = 0; i < kLetterPhases.length; i++)
                            _LetterTile(
                              letter: kLetterPhases[i].letter,
                              size: tile,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LetterSoundsScreen(phaseIndex: i),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Testa cada nº de colunas e fica com o que deixa o botão maior, com a
  /// grade inteira dentro de [width] x [height].
  static double _fittingTileSize(double width, double height, double gap) {
    final count = kLetterPhases.length;
    var best = 0.0;
    for (var columns = 1; columns <= count; columns++) {
      final rows = (count / columns).ceil();
      final size = math.min(
        (width - (columns - 1) * gap) / columns,
        (height - (rows - 1) * gap) / rows,
      );
      best = math.max(best, size);
    }
    return best;
  }
}

class _LetterTile extends StatelessWidget {
  final String letter;
  final double size;
  final VoidCallback onTap;

  const _LetterTile({
    required this.letter,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.22);

    return Material(
      color: kLetterSoundsColor,
      borderRadius: radius,
      elevation: 3,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          GameAudio.instance.play(Sfx.tap);
          onTap();
        },
        child: SizedBox.square(
          dimension: size,
          child: Padding(
            padding: EdgeInsets.all(size * 0.12),
            child: FittedBox(
              // Maiúscula grande e minúscula menor, como no card da letra
              // dentro do jogo: a criança já liga as duas formas no menu.
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: letter),
                    TextSpan(
                      text: letter.toLowerCase(),
                      style: const TextStyle(fontSize: 34),
                    ),
                  ],
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
