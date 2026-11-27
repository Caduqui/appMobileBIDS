import 'dart:async';

import 'package:flutter/widgets.dart';

/// Efeitos sonoros curtos. Arquivos em `assets/sfx/` (WAV: abrem sem
/// decodificar, então o som sai no toque). Origem e licença no AGENTS.md.
enum Sfx {
  /// Toque em botão/card de navegação.
  tap('sfx/tap.wav'),

  /// Carta da memória virando.
  flip('sfx/flip.wav'),

  /// Letra certa encaixando na lacuna (Complete a Palavra).
  place('sfx/place.wav'),

  /// Par encontrado / palavra completa.
  correct('sfx/correct.wav'),

  /// Par errado / letra errada. Grave e curto: avisa sem assustar.
  wrong('sfx/wrong.wav'),

  /// Fase completa.
  win('sfx/win.wav');

  const Sfx(this.asset);

  /// Caminho relativo a `assets/` (o prefixo que o audioplayers usa).
  final String asset;
}

/// Músicas de fundo, em loop. Uma por contexto: menus e jogos.
enum MusicTrack {
  /// Lobby e todas as telas de escolha (jogo, dificuldade, fase, letra).
  menu('music/menu.mp3', 0.5),

  /// Dentro dos minigames. Mais baixa que a do menu: ali tem fala e a
  /// criança precisa prestar atenção.
  game('music/game.mp3', 0.3);

  const MusicTrack(this.asset, this.volume);

  final String asset;

  /// Volume do player (0–1) sobre o arquivo já normalizado
  /// (`tool/treat_sound.sh`, média -20 dB, contra -14 dB das falas). Baixo de
  /// propósito: a do jogo fica ~16 dB abaixo das falas, e ainda some
  /// durante elas no Sons das Letras ([GameAudio.setDucked]).
  final double volume;
}

/// Quem de fato toca o som. Separado do [GameAudio] pra a regra (qual música,
/// quando abaixar) ser testável sem plugin nativo, e pra os testes de widget
/// rodarem mudos: o padrão é o [SilentAudioBackend] e só o `main()` liga o
/// de verdade (`AudioplayersBackend`).
abstract class AudioBackend {
  Future<void> init();
  Future<void> playSfx(Sfx sfx, double volume);

  /// Troca a música (a anterior para) e toca em loop.
  Future<void> playMusic(MusicTrack track, double volume);
  Future<void> setMusicVolume(double volume);
  Future<void> pauseMusic();
  Future<void> resumeMusic();

  /// Toca uma fala (caminho relativo a `assets/`) e só completa quando ela
  /// acaba — ou quando outra fala/[stopVoice] a interrompe.
  Future<void> playVoice(String asset, double volume);
  Future<void> stopVoice();

  /// Deixa as falas prontas pra tocar sem atraso no primeiro toque.
  Future<void> preload(List<String> assets);
}

class SilentAudioBackend implements AudioBackend {
  const SilentAudioBackend();

  @override
  Future<void> init() async {}
  @override
  Future<void> playSfx(Sfx sfx, double volume) async {}
  @override
  Future<void> playMusic(MusicTrack track, double volume) async {}
  @override
  Future<void> setMusicVolume(double volume) async {}
  @override
  Future<void> pauseMusic() async {}
  @override
  Future<void> resumeMusic() async {}
  @override
  Future<void> playVoice(String asset, double volume) async {}
  @override
  Future<void> stopVoice() async {}
  @override
  Future<void> preload(List<String> assets) async {}
}

/// Som do app inteiro: efeitos e música de fundo. Um só ([instance]), porque
/// a música atravessa as telas — trocar de tela no mesmo contexto (menu →
/// dificuldade → fase) não pode reiniciar a faixa.
///
/// Toda falha de áudio é engolida com um `debugPrint`: som é enfeite, nunca
/// pode travar a navegação nem o jogo.
class GameAudio {
  GameAudio([AudioBackend backend = const SilentAudioBackend()])
    : _backend = backend;

  static final GameAudio instance = GameAudio();

  /// Volume dos efeitos sobre o arquivo normalizado.
  static const sfxVolume = 0.6;

  /// Falas no máximo: o volume vem do arquivo, normalizado igual às do Sons
  /// das Letras (`tool/treat_audio.sh`).
  static const voiceVolume = 1.0;

  /// Quanto esperar depois da fala acabar pra a música voltar: tocando de
  /// novo logo em seguida (a criança toca várias vezes), a música não fica
  /// subindo e descendo entre um toque e outro.
  static const unduckDelay = Duration(milliseconds: 600);

  AudioBackend _backend;
  AppLifecycleListener? _lifecycle;
  MusicTrack? _track;
  bool _ducked = false;
  bool _hidden = false;
  Timer? _unduckTimer;

  /// Incrementa a cada [say]/[stopVoice]: uma sequência de falas antiga
  /// (ex.: "Melão… Parabéns!") para assim que outra começa.
  int _voiceRound = 0;

  MusicTrack? get currentTrack => _track;
  bool get isDucked => _ducked;

  /// Liga o som de verdade. Chamado só pelo `main()`.
  void start(AudioBackend backend) {
    _backend = backend;
    _run(backend.init);
    // App em segundo plano não toca música: a criança saiu do app (ou o
    // celular bloqueou) e a música continuaria lá fora.
    _lifecycle ??= AppLifecycleListener(onHide: appHidden, onShow: appShown);
  }

  void play(Sfx sfx) {
    if (_hidden) return;
    _run(() => _backend.playSfx(sfx, sfxVolume));
  }

  /// Toca [track] em loop. Se já é a que está tocando, não faz nada — é o
  /// que deixa a música seguir sem cortar entre as telas do mesmo contexto.
  void playMusic(MusicTrack track) {
    if (_track == track) return;
    _track = track;
    _run(() async {
      await _backend.playMusic(track, _musicVolume);
      if (_hidden) await _backend.pauseMusic();
    });
  }

  /// Fala [clips] em sequência (caminhos relativos a `assets/`), com a música
  /// abaixada. Completa com `true` quando a sequência terminou (ou o áudio
  /// falhou: aí quem chamou segue, ex. tocando a vinheta) e `false` quando
  /// outra fala ou [stopVoice] interrompeu — quem chamou não deve continuar.
  Future<bool> say(List<String> clips) async {
    final round = ++_voiceRound;
    if (_hidden) return false;
    setDucked(true);
    try {
      for (final clip in clips) {
        await _backend.playVoice(clip, voiceVolume);
        if (round != _voiceRound) return false;
      }
    } catch (error) {
      debugPrint('GameAudio: $error');
    } finally {
      if (round == _voiceRound) setDucked(false);
    }
    return round == _voiceRound;
  }

  /// Corta a fala em andamento. [now] devolve a música na hora (ao sair da
  /// tela, pra não deixar timer pendurado).
  void stopVoice({bool now = false}) {
    _voiceRound++;
    _run(_backend.stopVoice);
    setDucked(false, now: now);
  }

  void preload(List<String> clips) => _run(() => _backend.preload(clips));

  /// Abaixa a música enquanto uma fala toca (Sons das Letras): a criança
  /// precisa ouvir o som da letra, e a boca está sincronizada com ele.
  /// Abaixa na hora; volta depois de [unduckDelay], ou na hora com [now]
  /// (ao sair da tela, pra não deixar timer pendurado).
  void setDucked(bool ducked, {bool now = false}) {
    _unduckTimer?.cancel();
    _unduckTimer = null;
    if (ducked || now) {
      _applyDuck(ducked);
    } else if (_ducked) {
      _unduckTimer = Timer(unduckDelay, () => _applyDuck(false));
    }
  }

  void _applyDuck(bool ducked) {
    if (_ducked == ducked) return;
    _ducked = ducked;
    if (_track != null) _run(() => _backend.setMusicVolume(_musicVolume));
  }

  @visibleForTesting
  void appHidden() {
    if (_hidden) return;
    _hidden = true;
    if (_track != null) _run(_backend.pauseMusic);
  }

  @visibleForTesting
  void appShown() {
    if (!_hidden) return;
    _hidden = false;
    if (_track != null) _run(_backend.resumeMusic);
  }

  double get _musicVolume => _ducked ? 0 : (_track?.volume ?? 0);

  void _run(Future<void> Function() action) {
    try {
      unawaited(
        action().catchError((Object error) {
          debugPrint('GameAudio: $error');
        }),
      );
    } catch (error) {
      debugPrint('GameAudio: $error');
    }
  }
}
