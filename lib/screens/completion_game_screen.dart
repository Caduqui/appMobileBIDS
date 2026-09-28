import 'package:flutter/material.dart';

import '../controllers/completion_game_controller.dart';
import '../data/completion_phases.dart';
import '../models/completion_models.dart';
import '../models/difficulty.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/shake_widget.dart';
import '../widgets/word_image.dart';
import 'difficulty_screen.dart';

class CompletionGameScreen extends StatefulWidget {
  final Difficulty difficulty;
  final int phaseIndex;

  const CompletionGameScreen({
    super.key,
    required this.difficulty,
    required this.phaseIndex,
  });

  @override
  State<CompletionGameScreen> createState() => _CompletionGameScreenState();
}

class _CompletionGameScreenState extends State<CompletionGameScreen> {
  late final CompletionGameController _controller;
  int _celebrateKey = 0;
  int _wrongKey = 0;

  List<CompletionPhase> get _phases => kCompletionPhases[widget.difficulty]!;
  CompletionPhase get _phase => _phases[widget.phaseIndex];
  bool get _hasNextPhase => widget.phaseIndex + 1 < _phases.length;

  @override
  void initState() {
    super.initState();
    _controller = CompletionGameController(
      words: _phase.words,
      missingLetters: widget.difficulty.missingLetters,
    );
    _controller.onWrongLetter = () => setState(() => _wrongKey++);
    _controller.onWordSolved = () => setState(() => _celebrateKey++);
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
        builder: (_) => CompletionGameScreen(
          difficulty: widget.difficulty,
          phaseIndex: widget.phaseIndex + 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _controller.status;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Text(
                'Palavra ${_controller.wordIndex + 1} de ${_controller.wordCount}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                      child: WordImage(item: _controller.currentWord),
                    ),
                    CelebrationOverlay(triggerKey: _celebrateKey),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ShakeWidget(
                triggerKey: _wrongKey,
                child: _buildSlots(),
              ),
              const SizedBox(height: 20),
              _buildTiles(),
              const SizedBox(height: 16),
              _buildFooter(status),
            ],
          ),
        ),
      ),
    );
  }

  /// A palavra numa linha só: o tamanho de cada casinha encolhe conforme a
  /// palavra é longa ("Helicóptero" precisa caber na largura do celular).
  Widget _buildSlots() {
    const spacing = 6.0;
    final slots = _controller.slots;
    final playing = _controller.status == CompletionStatus.playing;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = ((constraints.maxWidth - spacing * (slots.length - 1)) / slots.length)
            .clamp(24.0, 52.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slots.length; i++) ...[
              if (i > 0) const SizedBox(width: spacing),
              _SlotBox(
                slot: slots[i],
                width: width,
                selected: playing && i == _controller.selectedSlot,
                onTap: () => _controller.onSlotTap(i),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTiles() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final tile in _controller.tiles)
          // maintainSize: a letra usada some, mas o espaço dela fica —
          // senão as outras letras "pulariam" de lugar a cada acerto.
          Visibility(
            visible: !tile.used,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: _TileButton(
              letter: tile.letter,
              onTap: () => _controller.onTileTap(tile),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(CompletionStatus status) {
    // Altura fixa: os botões aparecem sem empurrar o resto da tela.
    return SizedBox(
      height: 52,
      child: switch (status) {
        CompletionStatus.playing => const SizedBox.shrink(),
        CompletionStatus.wordSolved => Center(
            child: _FooterButton(
              icon: Icons.arrow_forward,
              label: 'Próxima palavra',
              color: Colors.orange,
              onPressed: _controller.nextWord,
            ),
          ),
        CompletionStatus.phaseCompleted => Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              _FooterButton(
                icon: Icons.replay,
                label: 'Jogar novamente',
                color: Colors.teal,
                onPressed: _controller.startPhase,
              ),
              if (_hasNextPhase)
                _FooterButton(
                  icon: Icons.arrow_forward,
                  label: 'Próxima fase',
                  color: Colors.orange,
                  onPressed: _goToNextPhase,
                ),
            ],
          ),
      },
    );
  }
}

class _SlotBox extends StatelessWidget {
  final LetterSlot slot;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  const _SlotBox({
    required this.slot,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Três aparências: letra dada (branca), lacuna vazia (borda laranja,
    // grossa quando selecionada) e lacuna preenchida pela criança (verde).
    final Color background;
    final Color border;
    if (!slot.isBlank) {
      background = Colors.white;
      border = Colors.grey.shade400;
    } else if (slot.isFilled) {
      background = Colors.green.shade100;
      border = Colors.green;
    } else {
      background = Colors.white;
      border = Colors.orange;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: width * 1.25,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: selected ? 4 : 2),
        ),
        child: slot.isFilled
            ? Text(
                slot.char,
                style: TextStyle(
                  fontSize: width * 0.7,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              )
            : null,
      ),
    );
  }
}

class _TileButton extends StatelessWidget {
  final String letter;
  final VoidCallback onTap;

  const _TileButton({required this.letter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.teal,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          letter,
          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _FooterButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
