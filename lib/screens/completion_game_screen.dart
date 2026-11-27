import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../audio/game_audio.dart';
import '../audio/voice_clips.dart';
import '../controllers/completion_game_controller.dart';
import '../data/completion_phases.dart';
import '../models/completion_models.dart';
import '../models/difficulty.dart';
import '../models/word_item.dart';
import '../utils/responsive.dart';
import '../widgets/background_music.dart';
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
  /// Quanto tempo a letra errada fica vermelha: o tremido (400 ms) e mais
  /// um pouquinho pra criança ver qual foi.
  static const _wrongDuration = Duration(milliseconds: 700);

  late final CompletionGameController _controller;
  final _random = Random();
  int _celebrateKey = 0;

  /// A última letra tocada na bandeja: o controller só avisa "acertou" /
  /// "errou", e a tela precisa saber qual letra falar ou deixar vermelha.
  LetterTile? _tappedTile;

  /// Letra errada (vermelha e tremendo) e o contador do tremido por letra:
  /// um contador por letra porque o ShakeWidget treme quando o número muda.
  int? _wrongTileId;
  final Map<int, int> _shakeKeys = {};
  Timer? _wrongTimer;

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
    _controller.onWrongLetter = _onWrongLetter;
    _controller.onLetterPlaced = () {
      // A voz fala o nome da letra certa ("eme"). A última letra da palavra
      // não: ali quem fala é a palavra inteira (onWordSolved).
      final tile = _tappedTile;
      if (tile != null) {
        unawaited(GameAudio.instance.say([letterNameClip(tile.letter)]));
      }
    };
    _controller.onWordSolved = () {
      setState(() => _celebrateKey++);
      unawaited(_celebrate(_controller.currentWord));
    };
    _controller.addListener(_onControllerChanged);
    _controller.startPhase();

    // Abre as falas já: abrindo só no toque, o nome da letra sairia atrasado.
    GameAudio.instance.preload([
      for (final word in _phase.words) wordClip(word),
      for (final letter in 'abcdefghijklmnopqrstuvwxyz'.split(''))
        letterNameClip(letter),
      ...cheerClips,
    ]);
  }

  /// "Melão" … "Parabéns!" e a vinheta de vitória. Se a criança já passou
  /// pra próxima palavra no meio (a fala foi cortada), não toca o resto.
  Future<void> _celebrate(WordItem word) async {
    final cheer = cheerClips[_random.nextInt(cheerClips.length)];
    final finished = await GameAudio.instance.say([wordClip(word), cheer]);
    if (finished && mounted) GameAudio.instance.play(Sfx.win);
  }

  void _onWrongLetter() {
    final tile = _tappedTile;
    if (tile == null) return;
    GameAudio.instance.play(Sfx.wrong);
    _wrongTimer?.cancel();
    setState(() {
      _wrongTileId = tile.id;
      _shakeKeys[tile.id] = (_shakeKeys[tile.id] ?? 0) + 1;
    });
    _wrongTimer = Timer(_wrongDuration, () {
      if (mounted) setState(() => _wrongTileId = null);
    });
  }

  void _onTileTap(LetterTile tile) {
    _tappedTile = tile;
    _controller.onTileTap(tile);
  }

  /// Próxima palavra / jogar de novo: corta a comemoração que ainda estiver
  /// falando, senão ela atropelaria a palavra nova.
  void _nextWord() {
    GameAudio.instance.stopVoice();
    _controller.nextWord();
  }

  void _playAgain() {
    GameAudio.instance.stopVoice();
    _controller.startPhase();
  }

  void _onControllerChanged() => setState(() {});

  @override
  void dispose() {
    _wrongTimer?.cancel();
    // Na hora: a tela está saindo e não pode deixar timer de música.
    GameAudio.instance.stopVoice(now: true);
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: isLandscape(context)
                ? _buildLandscape(status)
                : _buildPortrait(status),
          ),
        ),
      ),
    );
  }

  /// Empilhado: a palavra em cima (ocupa o espaço que sobra), controles
  /// embaixo. Funciona bem numa tela mais alta que larga.
  Widget _buildPortrait(CompletionStatus status) {
    return Column(
      children: [
        _buildProgressText(),
        const SizedBox(height: 8),
        Expanded(child: _buildWordCard()),
        const SizedBox(height: 20),
        _buildSlots(),
        const SizedBox(height: 20),
        _buildTiles(),
        const SizedBox(height: 16),
        _buildFooter(status),
      ],
    );
  }

  /// Lado a lado: a palavra à esquerda, controles à direita. Numa tela
  /// baixa (celular deitado), empilhar tudo verticalmente espremeria demais
  /// a imagem da palavra — aqui ela mantém uma área decente mesmo com pouca
  /// altura disponível.
  Widget _buildLandscape(CompletionStatus status) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 4, child: _buildWordCard()),
        const SizedBox(width: 20),
        Expanded(
          flex: 5,
          // LayoutBuilder + ConstrainedBox(minHeight) + Center: centraliza
          // verticalmente quando cabe (o caso comum) e deixa rolar quando não
          // cabe, em vez de estourar o layout — numa tela de celular bem
          // baixa (deitado), o Médio/Difícil pode ter peças suficientes pra
          // quebrar em 2 linhas no Wrap e não caber na altura disponível.
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildProgressText(),
                        const SizedBox(height: 12),
                        _buildSlots(),
                        const SizedBox(height: 12),
                        _buildTiles(),
                        const SizedBox(height: 12),
                        _buildFooter(status),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressText() {
    return Text(
      'Palavra ${_controller.wordIndex + 1} de ${_controller.wordCount}',
      style: TextStyle(
        fontSize: responsiveValue(context, phone: 16.0, tablet: 20.0),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildWordCard() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: WordImage(item: _controller.currentWord),
        ),
        CelebrationOverlay(triggerKey: _celebrateKey),
      ],
    );
  }

  /// A palavra numa linha só: o tamanho de cada casinha encolhe conforme a
  /// palavra é longa ("Helicóptero" precisa caber na largura do celular) e
  /// cresce num tablet (mais espaço, letras maiores e mais fáceis de tocar).
  Widget _buildSlots() {
    const spacing = 6.0;
    final slots = _controller.slots;
    final playing = _controller.status == CompletionStatus.playing;
    final minWidth = responsiveValue(context, phone: 24.0, tablet: 36.0);
    final maxWidth = responsiveValue(context, phone: 52.0, tablet: 76.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            ((constraints.maxWidth - spacing * (slots.length - 1)) /
                    slots.length)
                .clamp(minWidth, maxWidth);
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
            // Letra errada: fica vermelha e treme na horizontal, só ela.
            child: ShakeWidget(
              triggerKey: _shakeKeys[tile.id] ?? 0,
              child: _TileButton(
                letter: tile.letter,
                wrong: tile.id == _wrongTileId,
                onTap: () => _onTileTap(tile),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(CompletionStatus status) {
    // Altura fixa: os botões aparecem sem empurrar o resto da tela.
    final height = responsiveValue(context, phone: 52.0, tablet: 64.0);
    return SizedBox(
      height: height,
      child: switch (status) {
        CompletionStatus.playing => const SizedBox.shrink(),
        CompletionStatus.wordSolved => Center(
          child: _FooterButton(
            icon: Icons.arrow_forward,
            label: 'Próxima palavra',
            color: Colors.orange,
            onPressed: _nextWord,
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
              onPressed: _playAgain,
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

  /// Acabou de ser tocada e não era a letra certa: fundo vermelho.
  final bool wrong;
  final VoidCallback onTap;

  const _TileButton({
    required this.letter,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = responsiveValue(context, phone: 56.0, tablet: 76.0);
    final fontSize = responsiveValue(context, phone: 30.0, tablet: 38.0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: wrong ? Colors.red : Colors.teal,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
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
    final fontSize = responsiveValue(context, phone: 14.0, tablet: 18.0);

    return ElevatedButton.icon(
      onPressed: () {
        GameAudio.instance.play(Sfx.tap);
        onPressed();
      },
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }
}
