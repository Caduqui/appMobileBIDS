import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../controllers/memory_game_controller.dart';
import '../data/memory_phases.dart';
import '../models/difficulty.dart';
import '../models/game_phase_status.dart';
import '../models/memory_card_model.dart';
import '../utils/responsive.dart';
import '../widgets/background_music.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/memory_card_widget.dart';
import 'difficulty_screen.dart';

class MemoryGameScreen extends StatefulWidget {
  final Difficulty difficulty;
  final int phaseIndex;

  const MemoryGameScreen({
    super.key,
    required this.difficulty,
    required this.phaseIndex,
  });

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  late final MemoryGameController _controller;
  int _celebrateKey = 0;

  List<MemoryPhase> get _phases => kMemoryPhases[widget.difficulty]!;
  MemoryPhase get _phase => _phases[widget.phaseIndex];
  bool get _hasNextPhase => widget.phaseIndex + 1 < _phases.length;

  @override
  void initState() {
    super.initState();
    _controller = MemoryGameController(
      items: _phase.items,
      previewDuration: Duration(seconds: widget.difficulty.previewSeconds),
    );
    _controller.onMatchFound = () {
      setState(() => _celebrateKey++);
      // O último par já é a fase completa: toca só a vitória, não os dois.
      final won = _controller.cards.every((c) => c.state == CardState.matched);
      GameAudio.instance.play(won ? Sfx.win : Sfx.correct);
    };
    _controller.onCardFlipped = () => GameAudio.instance.play(Sfx.flip);
    _controller.onMismatch = () => GameAudio.instance.play(Sfx.wrong);
    _controller.addListener(_onControllerChanged);
    _controller.startPhase();
  }

  void _onControllerChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _playAgain() {
    GameAudio.instance.play(Sfx.tap);
    _controller.startPhase();
  }

  void _goToNextPhase() {
    GameAudio.instance.play(Sfx.tap);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MemoryGameScreen(
          difficulty: widget.difficulty,
          phaseIndex: widget.phaseIndex + 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _controller.status == GamePhaseStatus.completed;

    return BackgroundMusic(
      track: MusicTrack.game,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8E7),
        appBar: AppBar(
          title: Text(
            '${widget.difficulty.label} · Fase ${widget.phaseIndex + 1} — ${_phase.title}',
            style: const TextStyle(fontSize: 18),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: difficultyColor(widget.difficulty),
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Limite de tamanho num tablet: sem ele, numa tela bem
                    // grande as cartas ficariam enormes só porque sobra
                    // espaço — melhor manter um tamanho confortável de jogar
                    // e deixar a sobra como moldura ao redor do grid.
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: responsiveValue(
                          context,
                          phone: double.infinity,
                          tablet: 1000,
                        ),
                        maxHeight: responsiveValue(
                          context,
                          phone: double.infinity,
                          tablet: 750,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const spacing = 8.0;

                            // O nº de colunas/linhas da dificuldade (ex.: 3x4 no
                            // Fácil) é pensado pra celular em pé. Em paisagem —
                            // tela mais larga que alta — as cartas ficariam
                            // esticadas horizontalmente se usássemos o mesmo
                            // layout; em vez disso, invertemos colunas e linhas
                            // (3x4 vira 4x3), mantendo o mesmo nº de cartas mas
                            // com cada uma próxima do formato quadrado.
                            final isWide =
                                constraints.maxWidth > constraints.maxHeight;
                            final columns = isWide
                                ? widget.difficulty.memoryRows
                                : widget.difficulty.memoryColumns;
                            final rows = isWide
                                ? widget.difficulty.memoryColumns
                                : widget.difficulty.memoryRows;

                            final totalHSpacing = spacing * (columns - 1);
                            final totalVSpacing = spacing * (rows - 1);

                            final tileWidth =
                                (constraints.maxWidth - totalHSpacing) /
                                columns;
                            final tileHeight =
                                (constraints.maxHeight - totalVSpacing) / rows;

                            return GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _controller.cards.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: spacing,
                                    mainAxisSpacing: spacing,
                                    childAspectRatio: tileWidth / tileHeight,
                                  ),
                              itemBuilder: (context, index) {
                                final card = _controller.cards[index];
                                return MemoryCardWidget(
                                  key: ValueKey(card.cardId),
                                  card: card,
                                  onTap: () => _controller.onCardTap(card),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    CelebrationOverlay(triggerKey: _celebrateKey),
                  ],
                ),
              ),
              if (isCompleted)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _playAgain,
                        icon: const Icon(Icons.replay),
                        label: const Text('Jogar novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      if (_hasNextPhase)
                        ElevatedButton.icon(
                          onPressed: _goToNextPhase,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Próxima fase'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
