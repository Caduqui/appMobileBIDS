import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linguagens/data/audio_envelopes.dart';
import 'package:linguagens/data/letter_phases.dart';
import 'package:linguagens/data/lip_sync.dart';
import 'package:linguagens/data/word_catalog.dart';
import 'package:linguagens/models/mouth_pose.dart';

LetterPhase _phase(String letter) => kLetterPhases.firstWhere((p) => p.letter == letter);

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
      for (final phase in kLetterPhases) {
        for (final word in phase.words) {
          expect(kAudioEnvelopes, contains(wordAudioPath(word)), reason: word.name);
        }
      }
    });
  });

  group('trilha da letra', () {
    test('começa e termina em repouso, com o som depois da preparação da boca', () {
      for (final phase in kLetterPhases) {
        final track = letterTrack(phase);
        expect(track.frames.first.lips, closeTo(0, 0.05), reason: phase.title);
        expect(track.frames.last.lips, closeTo(0, 0.05), reason: phase.title);
        expect(track.soundStart, greaterThan(Duration.zero), reason: phase.title);
        expect(track.duration, greaterThan(track.soundStart), reason: phase.title);
      }
    });

    test('dura o áudio inteiro (a boca não fecha antes do som acabar)', () {
      for (final phase in kLetterPhases) {
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
      // Nos sons de lábio a língua já está na vogal seguinte.
      MouthPose lips(String l, String vowel) => m(l).withTongueOf(m(vowel));
      expect(wordPoses('Bola'), [lips('B', 'O'), m('O'), m('L'), m('A')]);
      // "qu" antes de "e": o "u" não soa; "o" final soa "u".
      expect(wordPoses('Queijo'), [m('Q'), m('E'), m('I'), m('J'), m('U')]);
      // "lh" é um som só, com o dorso da língua no palato (não é o "l").
      expect(wordPoses('Telhado'), [m('T'), m('E'), kLhPose, m('A'), m('D'), m('U')]);
      expect(wordPoses('Cozinha'), [m('C'), m('O'), m('S'), m('I'), kNhPose, m('A')]);
      // "l" no fim da sílaba soa "u"; "e" final soa "i".
      expect(
        wordPoses('Alfinete'),
        [m('A'), m('U'), lips('F', 'I'), m('I'), m('N'), m('E'), m('T'), m('I')],
      );
      // "ç" soa "s", "rr" é um som só (o "r" forte, no fundo da boca).
      expect(wordPoses('Carroça'), [m('C'), m('A'), m('R'), m('O'), m('S'), m('A')]);
      // "r" fraco (ponta da língua): entre vogais, depois de consoante e no
      // fim da sílaba; forte no começo da palavra.
      expect(wordPoses('Xícara'), [m('X'), m('I'), m('C'), m('A'), kTapPose, m('A')]);
      expect(wordPoses('Zebra')[3], kTapPose);
      expect(wordPoses('Porta'), [lips('P', 'O'), m('O'), kTapPose, m('T'), m('A')]);
      expect(wordPoses('Rato').first, m('R'));
    });

    test('a língua de cada som está no lugar certo', () {
      MouthPose m(String l) => _phase(l).mouth;
      // Ponta nos alvéolos.
      for (final l in const ['T', 'D', 'N', 'L']) {
        expect(m(l).tongueTip, 1, reason: l);
        expect(m(l).tongueBack, 0, reason: l);
      }
      expect(m('L').tongueNarrow, greaterThan(m('N').tongueNarrow), reason: 'L é fino');
      expect(kTapPose.tongueTip, greaterThan(0.5));
      // Fundo no véu.
      for (final l in const ['C', 'G', 'K', 'Q', 'R']) {
        expect(m(l).tongueBack, greaterThan(0.5), reason: l);
        expect(m(l).tongueTip, 0, reason: l);
      }
      // Dorso da frente no palato, ponta embaixo.
      for (final pose in [m('I'), kLhPose, kNhPose]) {
        expect(pose.tongueFront, 1);
        expect(pose.tongueTip, 0);
      }
      // Vogais: "A" deitada; "E"/"I" na frente; "O"/"U" atrás, "U" mais alto.
      expect(m('A').tongueFront + m('A').tongueBack + m('A').tongueTip, 0);
      expect(m('E').tongueFront, inExclusiveRange(0, m('I').tongueFront));
      expect(m('O').tongueBack, inExclusiveRange(0, m('U').tongueBack));
    });

    test('toda palavra tem trilha que começa e termina em repouso', () {
      for (final phase in kLetterPhases) {
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
