import 'package:flutter/material.dart';

import '../controllers/memory_game_controller.dart';
import '../data/memory_phases.dart';
import '../models/difficulty.dart';
import '../models/game_phase_status.dart';
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
    };
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

  void _goToNextPhase() {
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
    final columns = widget.difficulty.memoryColumns;
    final rows = widget.difficulty.memoryRows;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: Text(
          '${widget.difficulty.label} · Fase ${widget.phaseIndex + 1} — ${_phase.title}',
          style: const TextStyle(fontSize: 18),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 8.0;

                          final totalHSpacing = spacing * (columns - 1);
                          final totalVSpacing = spacing * (rows - 1);

                          final tileWidth =
                              (constraints.maxWidth - totalHSpacing) / columns;
                          final tileHeight =
                              (constraints.maxHeight - totalVSpacing) / rows;

                          return GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _controller.cards.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                      onPressed: () => _controller.startPhase(),
                      icon: const Icon(Icons.replay),
                      label: const Text('Jogar novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
