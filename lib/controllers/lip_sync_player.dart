import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

import '../models/mouth_pose.dart';

/// Toca uma [MouthTrack] junto com o áudio dela e expõe a [pose] da boca a
/// cada quadro de tela.
///
/// A boca anda num relógio próprio (um [Ticker], suave a 60+ fps) em vez
/// de seguir a posição do player, que o plugin só atualiza a cada 100 ms —
/// seguindo ela a boca andaria aos trancos. Mas o relógio é corrigido pela
/// posição real sempre que ela chega, então se o aparelho demorar pra
/// começar o som, a boca espera; se começar antes, ela alcança.
class LipSyncPlayer extends ChangeNotifier {
  LipSyncPlayer(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick);
  }

  /// Quanto o aparelho demora entre `play()` e o som sair. Começa com um
  /// chute e é aprendido a cada som tocado (static: vale pras próximas
  /// telas também).
  static Duration _latency = const Duration(milliseconds: 80);

  late final Ticker _ticker;
  MouthTrack? _track;
  VideoPlayerController? _audio;
  Future<void>? _ready;
  bool _audioRequested = false;
  bool _latencyLearned = false;
  Duration _elapsed = Duration.zero;

  /// Instante do relógio em que o áudio está (ou deveria estar) na
  /// posição zero. Só existe depois de pedir o play.
  Duration? _audioZero;

  MouthPose _pose = MouthPose.rest;
  MouthPose get pose => _pose;

  bool _disposed = false;

  /// Começa [track] do zero, com [audio] tocando a partir de
  /// `track.soundStart` (sem áudio, a boca anima em silêncio).
  void play(MouthTrack track, VideoPlayerController? audio) {
    _stopAudio();
    _ticker.stop();
    _track = track;
    _audio = audio;
    _audioRequested = false;
    _latencyLearned = false;
    _audioZero = null;
    if (audio != null) {
      audio.addListener(_onAudio);
      // Volta pro começo já, durante a preparação da boca, pra o play
      // depois não esperar o seek.
      _ready = audio.pause().then((_) => audio.seekTo(Duration.zero));
    }
    _ticker.start();
  }

  void stop() {
    _stopAudio();
    _ticker.stop();
    _track = null;
    _setPose(MouthPose.rest);
  }

  void _stopAudio() {
    final audio = _audio;
    if (audio == null) return;
    audio.removeListener(_onAudio);
    unawaited(audio.pause());
    _audio = null;
  }

  void _onTick(Duration elapsed) {
    final track = _track;
    if (track == null) return;
    _elapsed = elapsed;
    final audio = _audio;

    if (audio != null && !_audioRequested && elapsed >= track.soundStart - _latency) {
      _audioRequested = true;
      _audioZero = elapsed + _latency;
      unawaited(_ready!.then((_) {
        // O usuário pode ter tocado em outra coisa enquanto o seek rodava.
        if (identical(_audio, audio)) return audio.play();
      }));
    }

    final zero = _audioZero;
    final t = zero == null ? elapsed : track.soundStart + (elapsed - zero);
    if (t >= track.duration) {
      _ticker.stop();
      _track = null;
      _setPose(MouthPose.rest);
      return;
    }
    _setPose(track.poseAt(t < Duration.zero ? Duration.zero : t));
  }

  /// Posição real do áudio chegou: acerta o relógio da boca por ela.
  void _onAudio() {
    final audio = _audio;
    final zero = _audioZero;
    if (audio == null || zero == null || !audio.value.isPlaying) return;
    final position = audio.value.position;
    if (position <= Duration.zero || position >= audio.value.duration) return;

    final measured = _elapsed - position;
    final error = measured - zero;
    if (error.abs() > const Duration(milliseconds: 400)) return;
    // Corrige aos poucos: um pulo seco seria visível na boca.
    _audioZero = zero + error * 0.4;
    if (!_latencyLearned) {
      _latencyLearned = true;
      final learned = _latency + error * 0.5;
      _latency = learned < Duration.zero
          ? Duration.zero
          : learned > const Duration(milliseconds: 300)
          ? const Duration(milliseconds: 300)
          : learned;
    }
  }

  void _setPose(MouthPose pose) {
    _pose = pose;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopAudio();
    _ticker.dispose();
    super.dispose();
  }
}
