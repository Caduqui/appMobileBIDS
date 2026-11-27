import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'game_audio.dart';

/// O [AudioBackend] de verdade, com o plugin `audioplayers`.
///
/// Por que outro plugin além do `video_player` (que toca as falas do Sons das
/// Letras): o `video_player` abre um player pesado por arquivo e demora pra
/// começar, então o clique de um botão sairia atrasado. Aqui os efeitos ficam
/// pré-carregados em modo de baixa latência (SoundPool no Android) e a música
/// tem um player só, em loop.
class AudioplayersBackend implements AudioBackend {
  /// Players por efeito: dois, pra um toque rápido logo depois do outro
  /// (duas cartas viradas em seguida) não cortar o primeiro som.
  static const _playersPerSfx = 2;

  final Map<Sfx, List<AudioPlayer>> _sfx = {};
  final Map<Sfx, int> _next = {};

  /// O player da música, pronto. Um Future porque o lobby já pede a música
  /// no primeiro quadro, antes do init terminar: o pedido espera em vez de
  /// se perder.
  late final Future<AudioPlayer> _music = _createMusicPlayer();

  Future<AudioPlayer> _createMusicPlayer() async {
    // "Misturar com os outros": sem isso o Android daria o foco de áudio a
    // este plugin e o video_player pausaria a fala da letra (e vice-versa);
    // no iOS a sessão de áudio de um interromperia o outro.
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
    );
    final music = AudioPlayer(playerId: 'music');
    await music.setReleaseMode(ReleaseMode.loop);
    return music;
  }

  @override
  Future<void> init() async {
    await _music;
    for (final sfx in Sfx.values) {
      final players = <AudioPlayer>[];
      for (var i = 0; i < _playersPerSfx; i++) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(sfx.asset));
        players.add(player);
      }
      _sfx[sfx] = players;
    }
  }

  @override
  Future<void> playSfx(Sfx sfx, double volume) async {
    final players = _sfx[sfx];
    if (players == null) return; // ainda carregando: melhor mudo que atrasado
    final index = _next[sfx] ?? 0;
    _next[sfx] = (index + 1) % players.length;
    final player = players[index];
    await player.stop();
    // Cada chamada ao plugin atrasa o som um pouco: o volume só vai quando
    // muda (na prática, uma vez por player).
    if (_volumes[player] != volume) {
      _volumes[player] = volume;
      await player.setVolume(volume);
    }
    await player.resume();
  }

  final Map<AudioPlayer, double> _volumes = {};

  @override
  Future<void> playMusic(MusicTrack track, double volume) =>
      _musicOp((music) async {
        await music.stop();
        await music.setVolume(volume);
        await music.play(AssetSource(track.asset));
      });

  @override
  Future<void> setMusicVolume(double volume) =>
      _musicOp((music) => music.setVolume(volume));

  @override
  Future<void> pauseMusic() => _musicOp((music) => music.pause());

  @override
  Future<void> resumeMusic() => _musicOp((music) => music.resume());

  /// Player das falas do Complete a Palavra (nome da letra, palavra,
  /// comemoração). Separado da música, que segue tocando baixinho.
  late final Future<AudioPlayer> _voice = _music.then((_) async {
    final voice = AudioPlayer(playerId: 'voice');
    await voice.setReleaseMode(ReleaseMode.stop);
    return voice;
  });

  /// Quem está esperando a fala atual acabar. Completado também quando
  /// outra fala começa ou [stopVoice] corta, pra ninguém ficar esperando.
  Completer<void>? _voiceDone;

  @override
  Future<void> playVoice(String asset, double volume) async {
    final voice = await _voice;
    _finishVoice();
    final done = _voiceDone = Completer<void>();
    // Ouve o fim antes do play: uma fala curtinha poderia acabar antes.
    final subscription = voice.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    try {
      await voice.stop();
      await voice.setVolume(volume);
      await voice.play(AssetSource(asset));
      // Rede de segurança: se o fim nunca chegar, a sequência não trava.
      await done.future.timeout(const Duration(seconds: 6), onTimeout: () {});
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<void> stopVoice() async {
    _finishVoice();
    await (await _voice).stop();
  }

  void _finishVoice() {
    final done = _voiceDone;
    if (done != null && !done.isCompleted) done.complete();
  }

  @override
  Future<void> preload(List<String> assets) async {
    await _music;
    await AudioCache.instance.loadAll(assets);
  }

  /// Fila das operações da música: cada uma espera a anterior. Sem isso, duas
  /// trocas seguidas (entrar e sair de um jogo rápido) se intercalariam
  /// entre os `await` e a faixa errada poderia ficar tocando.
  Future<void> _musicQueue = Future.value();

  Future<void> _musicOp(Future<void> Function(AudioPlayer music) op) {
    final result = _musicQueue.then((_) async => op(await _music));
    // A fila segue mesmo se uma operação falhar; o erro vai pra quem chamou.
    _musicQueue = result.catchError((Object _) {});
    return result;
  }
}
