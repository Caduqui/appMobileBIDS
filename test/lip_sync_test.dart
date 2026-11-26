import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linguagens/data/audio_envelopes.dart';
import 'package:linguagens/data/letter_phases.dart';
import 'package:linguagens/data/lip_sync.dart';
import 'package:linguagens/data/word_catalog.dart';
import 'package:linguagens/models/difficulty.dart';
import 'package:linguagens/models/mouth_pose.dart';

final _phases = [for (final d in Difficulty.values) ...kLetterPhases[d]!];
LetterPhase _phase(String letter) => _phases.firstWhere((p) => p.letter == letter);

void main() {
  group('curvas de volume (lib/data/audio_envelopes.dart)', () {
    test('todo áudio em assets/audio tem curva — e nenhuma curva sobra', () {
      // Se falhar: rode `dart run tool/gen_audio_envelopes.dart` (precisa do
      // ffmpeg) depois de adicionar/trocar/apagar um áudio.
      final files = {
        for (final folder in const ['assets/audio/letters', 'assets/audio/words'])
          ...Directory(folder)
              .listSync()
              .whereType<File>()
              .map((f) => f.path.replaceAll(r'\', '/'))
              .where((p) => p.endsWith('.mp3')),
      };
      expect(kAudioEnvelopes.keys.toSet(), files);
    });

    test('toda palavra de exemplo tem áudio (a boca fala junto com ela)', () {
      for (final phase in _phases) {
        for (final word in phase.words) {
          expect(kAudioEnvelopes, contains(wordAudioPath(word)), reason: word.name);
        }
      }
    });
  });

  group('trilha da letra', () {
    test('começa e termina em repouso, com o som depois da preparação da boca', () {
      for (final phase in _phases) {
        final track = letterTrack(phase);
        expect(track.frames.first.lips, closeTo(0, 0.05), reason: phase.title);
        expect(track.frames.last.lips, closeTo(0, 0.05), reason: phase.title);
        expect(track.soundStart, greaterThan(Duration.zero), reason: phase.title);
        expect(track.duration, greaterThan(track.soundStart), reason: phase.title);
      }
    });

    test('dura o áudio inteiro (a boca não fecha antes do som acabar)', () {
      for (final phase in _phases) {
        final envelope = kAudioEnvelopes[phase.audioPath];
        if (envelope == null) continue;
        final track = letterTrack(phase);
        expect(
          track.duration - track.soundStart,
          greaterThanOrEqualTo(Duration(milliseconds: envelope.length * kEnvelopeStepMs)),
          reason: phase.title,
        );
      }
    });

    test('som segurado: no meio do som a boca está na pose da letra', () {
      for (final letter in const ['A', 'E', 'I', 'O', 'U', 'F', 'S', 'M', 'L']) {
        final phase = _phase(letter);
        final track = letterTrack(phase);
        final soundLength = track.duration - track.soundStart - const Duration(milliseconds: 220);
        final pose = track.poseAt(track.soundStart + soundLength * 0.4);
        expect(pose.lips, closeTo(phase.mouth.lips, 0.15), reason: letter);
        expect(pose.round, closeTo(phase.mouth.round, 0.15), reason: letter);
        expect(pose.press, closeTo(phase.mouth.press, 0.15), reason: letter);
      }
    });

    test('som que estoura: fechado no começo do áudio, solta depois do estouro', () {
      // "Fechado" = lábios apertados (B/P), ponta (T/D) ou fundo (C/G) da
      // língua encostados.
      double contact(MouthPose p) => p.press + p.tongueTip + p.tongueBack;
      for (final letter in const ['B', 'P', 'T', 'D', 'C', 'G']) {
        final track = letterTrack(_phase(letter));
        expect(contact(track.poseAt(track.soundStart)), greaterThan(0.8), reason: letter);
        final released = [
          for (var i = track.soundStart.inMilliseconds ~/ 10; i < track.frames.length; i++)
            contact(track.frames[i]),
        ].reduce((a, b) => a < b ? a : b);
        expect(released, lessThan(0.3), reason: letter);
      }
    });
  });

  group('trilha da palavra', () {
    test('um som por pose, com as regras de leitura', () {
      MouthPose m(String l) => _phase(l).mouth;
      expect(wordPoses('Bola'), [m('B'), m('O'), m('L'), m('A')]);
      // "qu" antes de "e": o "u" não soa; "o" final soa "u".
      expect(wordPoses('Queijo'), [m('Q'), m('E'), m('I'), m('J'), m('U')]);
      // "lh" é um som só.
      expect(wordPoses('Telhado'), [m('T'), m('E'), m('L'), m('A'), m('D'), m('U')]);
      // "l" no fim da sílaba soa "u"; "e" final soa "i".
      expect(wordPoses('Alfinete'), [m('A'), m('U'), m('F'), m('I'), m('N'), m('E'), m('T'), m('I')]);
      // "ç" soa "s", "rr" é um som só.
      expect(wordPoses('Carroça'), [m('C'), m('A'), m('R'), m('O'), m('S'), m('A')]);
      expect(wordPoses('Xícara').first, m('X'));
    });

    test('toda palavra tem trilha que começa e termina em repouso', () {
      for (final phase in _phases) {
        for (final word in phase.words) {
          final track = wordTrack(word);
          expect(track, isNotNull, reason: word.name);
          expect(track!.frames.first.lips, closeTo(0, 0.05), reason: word.name);
          expect(track.frames.last.lips, closeTo(0, 0.05), reason: word.name);
        }
      }
    });

    test('"Macaco": lábios fechados no "m" e abertos nos "a"', () {
      final track = wordTrack(Words.macaco)!;
      final frames = track.frames;
      final pressed = frames.indexWhere((p) => p.press > 0.3);
      expect(pressed, greaterThanOrEqualTo(0));
      final opened = frames.indexWhere((p) => p.lips > 0.5);
      expect(opened, greaterThan(pressed), reason: 'o "a" vem depois do "m"');
    });
  });
}
