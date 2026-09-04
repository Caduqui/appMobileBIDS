import 'package:flutter/material.dart';

import '../controllers/memory_game_controller.dart';
import '../models/game_phase_status.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/memory_card_widget.dart';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  final MemoryGameController _controller = MemoryGameController();
  int _celebrateKey = 0;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final isCompleted = _controller.status == GamePhaseStatus.completed;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
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
                          const crossAxisCount = 4;
                          const spacing = 8.0;

                          final totalHSpacing = spacing * (crossAxisCount - 1);
                          final totalVSpacing = spacing * (crossAxisCount - 1);

                          final tileWidth =
                              (constraints.maxWidth - totalHSpacing) / crossAxisCount;
                          final tileHeight =
                              (constraints.maxHeight - totalVSpacing) / crossAxisCount;

                          return GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _controller.cards.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
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
                child: ElevatedButton.icon(
                  onPressed: () => _controller.startPhase(),
                  icon: const Icon(Icons.replay),
                  label: const Text('Jogar novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}