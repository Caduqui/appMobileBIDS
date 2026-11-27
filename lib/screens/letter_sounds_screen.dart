import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../audio/game_audio.dart';
import '../controllers/lip_sync_player.dart';
import '../data/letter_phases.dart';
import '../data/lip_sync.dart';
import '../models/mouth_pose.dart';
import '../models/word_item.dart';
import '../utils/responsive.dart';
import '../widgets/background_music.dart';
import '../widgets/mouth_view.dart';
import '../widgets/word_image.dart';

/// O que aparece no card da boca.
/// - `mouth`: a boquinha animada — foto real deformada (o caso normal).
/// - `video`: existe um vídeo gravado pra letra; ele substitui o desenho.
enum _MouthStatus { loading, mouth, video, error }

/// Cor do Sons das Letras (barra, letra, destaque nas palavras e botões do
/// menu de letras). Sem dificuldade não há a cor de nível dos outros jogos;
/// é o roxo do card do jogo (`MinigameArt`), um pouco mais escuro pra o
/// texto branco por cima ter contraste.
const kLetterSoundsColor = Color(0xFF7E57C2);

/// Sons das Letras: a letra, a boquinha fazendo o som dela e palavras de
/// exemplo que começam com a letra. O som toca sozinho ao abrir e de novo a
/// cada toque (na letra, na boca ou em "Ouvir de novo"); tocar numa palavra
/// fala a palavra — com a boquinha falando junto.
///
/// Não tem controller de jogo em controllers/: não há regra, só tocar som e
/// mexer a boca. Quem toca é o VideoPlayerController do plugin (que também
/// serve pra áudio puro, por isso não há um plugin de áudio separado), e
/// quem mexe a boca no ritmo do áudio é o [LipSyncPlayer].
class LetterSoundsScreen extends StatefulWidget {
  /// Posição da letra em [kLetterPhases] (0 = A, 25 = Z).
  final int phaseIndex;

  const LetterSoundsScreen({super.key, required this.phaseIndex});

  @override
  State<LetterSoundsScreen> createState() => _LetterSoundsScreenState();
}

class _LetterSoundsScreenState extends State<LetterSoundsScreen>
    with SingleTickerProviderStateMixin {
  late final LipSyncPlayer _lipSync = LipSyncPlayer(this);

  /// Trilhas da boca, calculadas uma vez: da letra e de cada palavra que
  /// tem áudio.
  late final MouthTrack _letterTrack = letterTrack(_phase);
  late final Map<String, MouthTrack> _wordTracks = {
    for (final word in _phase.words) word.id: ?wordTrack(word),
  };

  /// Vídeo da boca (modo `video`) ou áudio da letra (modo `mouth`, pode ser
  /// nulo: sem arquivo de áudio a boquinha anima em silêncio).
  VideoPlayerController? _letterMedia;

  /// Áudio de cada palavra, aberto já ao entrar na tela: abrindo só no
  /// toque, o som saía atrasado (e a boca não tinha como acompanhar).
  final Map<String, VideoPlayerController> _wordAudio = {};

  Set<String> _assets = const {};
  _MouthStatus _status = _MouthStatus.loading;

  LetterPhase get _phase => kLetterPhases[widget.phaseIndex];
  // O alfabeto inteiro, sem parar em bloco nenhum: do A vai até o Z.
  bool get _hasNextPhase => widget.phaseIndex + 1 < kLetterPhases.length;

  /// A música de fundo está abaixada por causa de uma fala desta tela.
  bool _ducking = false;

  @override
  void initState() {
    super.initState();
    _lipSync.addListener(_updateDuck);
    _load();
  }

  /// Música de fundo some enquanto a letra ou a palavra toca: a criança
  /// precisa ouvir o som, e a boca está sincronizada com ele.
  void _updateDuck() {
    final speaking =
        _lipSync.isPlaying ||
        (_status == _MouthStatus.video && (_letterMedia?.value.isPlaying ?? false));
    if (speaking == _ducking) return;
    _ducking = speaking;
    GameAudio.instance.setDucked(speaking);
  }

  Future<void> _load() async {
    // Confere no manifesto o que existe: áudios e vídeos entram aos poucos,
    // e letra/palavra sem arquivo deve só ficar muda, não dar erro.
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    if (!mounted) return;
    _assets = manifest.listAssets().toSet();

    if (_assets.contains(_phase.videoPath)) {
      final video = await _open(_phase.videoPath);
      if (!mounted) {
        unawaited(video?.dispose());
        return;
      }
      _letterMedia = video;
      video?.addListener(_updateDuck);
      setState(() => _status = video == null ? _MouthStatus.error : _MouthStatus.video);
    } else {
      if (_assets.contains(_phase.audioPath)) {
        final audio = await _open(_phase.audioPath);
        if (!mounted) {
          unawaited(audio?.dispose());
          return;
        }
        _letterMedia = audio;
      }
      setState(() => _status = _MouthStatus.mouth);
    }
    unawaited(_loadWords());

    // Espera a transição de tela acabar: tocando com a tela ainda
    // deslizando, a criança perde o começo do som.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) _play();
  }

  Future<void> _loadWords() async {
    for (final word in _phase.words) {
      final path = wordAudioPath(word);
      if (!_assets.contains(path)) continue;
      final audio = await _open(path);
      if (!mounted) {
        unawaited(audio?.dispose());
        return;
      }
      if (audio != null) _wordAudio[word.id] = audio;
    }
  }

  /// Abre um vídeo/áudio dos assets. Devolve null se não der (arquivo
  /// corrompido, ou nos testes, onde o plugin não existe).
  Future<VideoPlayerController?> _open(String path) async {
    final controller = VideoPlayerController.asset(path);
    try {
      await controller.initialize();
      // Volume no máximo do player: o volume em si vem do arquivo, que já
      // é normalizado (ver AGENTS.md).
      await controller.setVolume(1);
      return controller;
    } catch (error) {
      debugPrint('LetterSoundsScreen: falha ao abrir $path ($error)');
      unawaited(controller.dispose());
      return null;
    }
  }

  void _play() {
    switch (_status) {
      case _MouthStatus.video:
        _lipSync.stop();
        _pauseWords();
        final video = _letterMedia;
        // Sempre do começo: um toque no meio recomeça em vez de pausar.
        if (video != null) unawaited(video.seekTo(Duration.zero).then((_) => video.play()));
      case _MouthStatus.mouth:
        _pauseWords();
        _lipSync.play(_letterTrack, _letterMedia);
      case _MouthStatus.loading || _MouthStatus.error:
        break;
    }
  }

  void _playWord(WordItem word) {
    final track = _wordTracks[word.id];
    final audio = _wordAudio[word.id];
    if (track == null || (audio == null && _assets.contains(wordAudioPath(word)))) {
      // Sem áudio (ou ainda abrindo): não mexe a boca à toa.
      return;
    }
    if (_status == _MouthStatus.video) unawaited(_letterMedia?.pause());
    _pauseWords();
    _lipSync.play(track, audio);
  }

  void _pauseWords() {
    for (final audio in _wordAudio.values) {
      if (audio.value.isPlaying) unawaited(audio.pause());
    }
  }

  @override
  void dispose() {
    // Na hora, sem esperar: a tela está saindo e não pode deixar timer.
    GameAudio.instance.setDucked(false, now: true);
    _lipSync.removeListener(_updateDuck);
    _letterMedia?.removeListener(_updateDuck);
    _lipSync.dispose();
    _letterMedia?.dispose();
    for (final audio in _wordAudio.values) {
      audio.dispose();
    }
    super.dispose();
  }

  void _goToNextPhase() {
    GameAudio.instance.play(Sfx.tap);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LetterSoundsScreen(phaseIndex: widget.phaseIndex + 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final letter = Center(child: _square(_buildLetterCard()));
    final mouth = Center(child: _square(_buildMouthCard()));

    return BackgroundMusic(
      track: MusicTrack.game,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8E7),
        appBar: AppBar(
          title: Text(
            'Sons das Letras — ${_phase.title}',
            style: const TextStyle(fontSize: 18),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: kLetterSoundsColor,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            // Letra e boca sempre lado a lado, cada uma num quadrado do maior
            // tamanho que couber (o Center solta a largura do Expanded pra o
            // AspectRatio poder encolher quando a altura é que limita). As
            // palavras vão pra onde sobra espaço: embaixo em retrato, numa
            // terceira coluna em paisagem.
            child: Column(
              children: [
                Expanded(
                  child: isLandscape(context)
                      ? Row(
                          children: [
                            Expanded(flex: 2, child: letter),
                            const SizedBox(width: 16),
                            Expanded(flex: 3, child: mouth),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: _buildWords()),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: letter),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 3, child: mouth),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 520),
                                  child: _buildWords(),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _square(Widget child) => AspectRatio(aspectRatio: 1, child: child);

  BoxDecoration _cardDecoration(Color color) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(20),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
    ],
  );

  Widget _buildLetterCard() {
    return GestureDetector(
      onTap: _play,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(Colors.white),
        child: FittedBox(
          // Maiúscula e minúscula juntas: a criança vê as duas formas da
          // mesma letra ligadas ao mesmo som.
          child: Text(
            '${_phase.letter}${_phase.letter.toLowerCase()}',
            style: TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.bold,
              color: kLetterSoundsColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMouthCard() {
    return GestureDetector(
      onTap: _play,
      child: Container(
        decoration: _cardDecoration(Colors.black),
        clipBehavior: Clip.antiAlias,
        child: switch (_status) {
          _MouthStatus.loading => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          _MouthStatus.mouth => _buildDrawnMouth(),
          _MouthStatus.video => Center(
            // Proporção real do vídeo, sem cortar (mesma regra das imagens
            // de card no AGENTS.md): se a gravação não for quadrada, sobra
            // faixa preta em vez de cortar a boca.
            child: AspectRatio(
              aspectRatio: _letterMedia!.value.aspectRatio,
              child: VideoPlayer(_letterMedia!),
            ),
          ),
          _MouthStatus.error => _VideoNotice(
            icon: Icons.error_outline,
            message: 'Não foi possível tocar o vídeo',
            detail: _phase.videoPath,
          ),
        },
      ),
    );
  }

  Widget _buildDrawnMouth() {
    final note = _phase.note;
    return Stack(
      fit: StackFit.expand,
      children: [
        ListenableBuilder(
          listenable: _lipSync,
          builder: (_, _) => MouthView(pose: _lipSync.pose),
        ),
        if (note != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Palavras de exemplo, uma por linha. Tudo em `Expanded` + `FittedBox`:
  /// encolhe pra caber em vez de estourar em tela baixa ou nome comprido.
  Widget _buildWords() {
    return Column(
      children: [
        for (final (index, word) in _phase.words.indexed) ...[
          if (index > 0) const SizedBox(height: 8),
          Expanded(
            child: _WordTile(
              word: word,
              letter: _phase.letter,
              color: kLetterSoundsColor,
              onTap: () => _playWord(word),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        _FooterButton(
          icon: Icons.volume_up,
          label: 'Ouvir de novo',
          color: Colors.teal,
          onPressed: _status == _MouthStatus.mouth || _status == _MouthStatus.video
              ? _play
              : null,
        ),
        if (_hasNextPhase)
          _FooterButton(
            icon: Icons.arrow_forward,
            label: 'Próxima letra',
            color: Colors.orange,
            onPressed: _goToNextPhase,
          ),
      ],
    );
  }
}

/// Uma palavra de exemplo: ilustração + nome, com a letra da fase destacada
/// na cor do jogo onde quer que ela apareça na palavra.
class _WordTile extends StatelessWidget {
  final WordItem word;
  final String letter;
  final Color color;
  final VoidCallback onTap;

  const _WordTile({
    required this.word,
    required this.letter,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = TextStyle(color: color);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Frações da largura, não um quadrado da altura: com só 2
            // palavras num tablet o tile fica mais alto que largo, e um
            // quadrado da altura não caberia.
            Expanded(flex: 2, child: WordImage(item: word)),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      for (final char in word.name.characters)
                        TextSpan(
                          text: char,
                          style: isSameLetter(char, letter) ? highlight : null,
                        ),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso no lugar do vídeo, com o caminho do arquivo que falhou.
class _VideoNotice extends StatelessWidget {
  final IconData icon;
  final String message;
  final String detail;

  const _VideoNotice({
    required this.icon,
    required this.message,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 48),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

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
      onPressed: onPressed,
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
