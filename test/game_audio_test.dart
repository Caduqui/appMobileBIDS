import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linguagens/audio/game_audio.dart';
import 'package:linguagens/audio/voice_clips.dart';
import 'package:linguagens/data/completion_phases.dart';

/// Backend que só anota o que pediram, pra testar a regra do [GameAudio]
/// sem plugin nativo.
class _RecordingBackend implements AudioBackend {
  final calls = <String>[];

  @override
  Future<void> init() async => calls.add('init');
  @override
  Future<void> playSfx(Sfx sfx, double volume) async =>
      calls.add('sfx ${sfx.name}');
  @override
  Future<void> playMusic(MusicTrack track, double volume) async =>
      calls.add('music ${track.name} $volume');
  @override
  Future<void> setMusicVolume(double volume) async =>
      calls.add('volume $volume');
  @override
  Future<void> pauseMusic() async => calls.add('pause');
  @override
  Future<void> resumeMusic() async => calls.add('resume');

  /// Com [holdVoices], cada fala só "acaba" quando o teste mandar
  /// ([finishVoice]) ou quando [stopVoice] cortar — como no aparelho.
  bool holdVoices = false;
  final _speaking = <Completer<void>>[];

  @override
  Future<void> playVoice(String asset, double volume) async {
    calls.add('voice $asset');
    if (!holdVoices) return;
    final done = Completer<void>();
    _speaking.add(done);
    await done.future;
  }

  void finishVoice() => _speaking.removeAt(0).complete();

  @override
  Future<void> stopVoice() async {
    calls.add('stopVoice');
    for (final done in _speaking) {
      done.complete();
    }
    _speaking.clear();
  }

  @override
  Future<void> preload(List<String> assets) async {}
}

/// Backend que sempre falha, como o plugin num aparelho sem áudio.
class _FailingBackend extends _RecordingBackend {
  @override
  Future<void> playSfx(Sfx sfx, double volume) => Future.error('sem áudio');
  @override
  Future<void> playMusic(MusicTrack track, double volume) =>
      throw StateError('sem áudio');
}

void main() {
  late _RecordingBackend backend;
  late GameAudio audio;

  setUp(() {
    backend = _RecordingBackend();
    audio = GameAudio(backend);
  });

  test(
    'pedir a música que já toca não reinicia (menu → dificuldade → fase)',
    () {
      audio.playMusic(MusicTrack.menu);
      audio.playMusic(MusicTrack.menu);
      audio.playMusic(MusicTrack.menu);
      expect(backend.calls, ['music menu ${MusicTrack.menu.volume}']);

      audio.playMusic(MusicTrack.game);
      audio.playMusic(MusicTrack.game);
      audio.playMusic(MusicTrack.menu);
      expect(backend.calls, [
        'music menu ${MusicTrack.menu.volume}',
        'music game ${MusicTrack.game.volume}',
        'music menu ${MusicTrack.menu.volume}',
      ]);
    },
  );

  test('música do jogo é mais baixa que a do menu', () {
    expect(MusicTrack.game.volume, lessThan(MusicTrack.menu.volume));
  });

  // testWidgets pelo relógio falso (tester.pump avança os Timers).
  testWidgets('fala abaixa a música na hora e ela volta depois de um tempo', (
    tester,
  ) async {
    audio.playMusic(MusicTrack.game);
    backend.calls.clear();

    audio.setDucked(true);
    expect(backend.calls, ['volume 0.0']);

    audio.setDucked(false);
    await tester.pump(GameAudio.unduckDelay - const Duration(milliseconds: 1));
    expect(backend.calls, ['volume 0.0'], reason: 'ainda esperando');

    await tester.pump(const Duration(milliseconds: 1));
    expect(backend.calls, ['volume 0.0', 'volume ${MusicTrack.game.volume}']);
  });

  testWidgets('tocar de novo logo depois da fala não faz a música subir', (
    tester,
  ) async {
    audio.playMusic(MusicTrack.game);
    backend.calls.clear();

    audio.setDucked(true);
    audio.setDucked(false);
    await tester.pump(GameAudio.unduckDelay ~/ 2);
    audio.setDucked(true); // a criança tocou de novo
    await tester.pump(GameAudio.unduckDelay * 2);
    expect(backend.calls, ['volume 0.0']);
    expect(audio.isDucked, isTrue);
  });

  testWidgets('sair da tela devolve a música na hora, sem timer pendurado', (
    tester,
  ) async {
    audio.playMusic(MusicTrack.game);
    audio.setDucked(true);
    audio.setDucked(false, now: true);
    expect(audio.isDucked, isFalse);
    // Um Timer pendurado faria o testWidgets falhar sozinho no fim.
  });

  test('trocar de música durante a fala já começa abaixada', () {
    audio.playMusic(MusicTrack.game);
    audio.setDucked(true);
    backend.calls.clear();
    audio.playMusic(MusicTrack.menu);
    expect(backend.calls, ['music menu 0.0']);
  });

  test('app em segundo plano pausa a música e silencia os efeitos', () {
    audio.playMusic(MusicTrack.menu);
    backend.calls.clear();

    audio.appHidden();
    audio.play(Sfx.tap);
    expect(backend.calls, ['pause']);

    audio.appShown();
    audio.play(Sfx.tap);
    expect(backend.calls, ['pause', 'resume', 'sfx tap']);
  });

  test('falha do áudio nunca vira exceção pra quem chamou', () async {
    final failing = GameAudio(_FailingBackend());
    expect(() => failing.play(Sfx.tap), returnsNormally);
    expect(() => failing.playMusic(MusicTrack.menu), returnsNormally);
    // Deixa os Futures com erro terminarem: se vazassem, o teste falharia.
    await Future<void>.delayed(Duration.zero);
  });

  testWidgets('falas em sequência com a música abaixada o tempo todo', (
    tester,
  ) async {
    audio.playMusic(MusicTrack.game);
    backend.calls.clear();
    backend.holdVoices = true;

    final result = audio.say(['voice/words/melao.mp3', cheerClips.first]);
    await tester.pump();
    expect(backend.calls, ['volume 0.0', 'voice voice/words/melao.mp3']);

    backend.finishVoice();
    await tester.pump();
    expect(backend.calls.last, 'voice ${cheerClips.first}');
    expect(audio.isDucked, isTrue, reason: 'entre uma fala e outra não sobe');

    backend.finishVoice();
    expect(await result, isTrue);
    await tester.pump(GameAudio.unduckDelay);
    expect(audio.isDucked, isFalse);
  });

  testWidgets('fala nova corta a anterior, que não continua a sequência', (
    tester,
  ) async {
    backend.holdVoices = true;
    final first = audio.say(['voice/words/melao.mp3', cheerClips.first]);
    await tester.pump();
    final second = audio.say([letterNameClip('M')]);
    await tester.pump();
    audio.stopVoice(now: true);

    expect(await first, isFalse);
    expect(await second, isFalse);
    expect(
      backend.calls.where((c) => c.startsWith('voice ')),
      ['voice voice/words/melao.mp3', 'voice voice/letter_names/m.mp3'],
      reason: 'a comemoração da primeira não toca depois de cortada',
    );
    expect(audio.isDucked, isFalse);
  });

  test('toda fala do Complete a Palavra existe em assets/voice/', () {
    final clips = {
      for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))
        letterNameClip(letter),
      for (final phases in kCompletionPhases.values)
        for (final phase in phases)
          for (final word in phase.words) wordClip(word),
      ...cheerClips,
    };
    for (final clip in clips) {
      expect(File('assets/$clip').existsSync(), isTrue, reason: clip);
    }
  });

  test('todo efeito e toda música existem em assets/', () {
    for (final asset in [
      for (final sfx in Sfx.values) sfx.asset,
      for (final track in MusicTrack.values) track.asset,
    ]) {
      expect(File('assets/$asset').existsSync(), isTrue, reason: asset);
    }
  });

  test(
    'sons ficam fora de assets/audio/ (lá todo mp3 precisa de curva da boca)',
    () {
      for (final asset in [
        for (final sfx in Sfx.values) sfx.asset,
        for (final track in MusicTrack.values) track.asset,
      ]) {
        expect(asset, isNot(startsWith('audio/')), reason: asset);
      }
    },
  );
}
