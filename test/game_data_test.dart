import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linguagens/controllers/completion_game_controller.dart';
import 'package:linguagens/data/completion_phases.dart';
import 'package:linguagens/data/letter_phases.dart';
import 'package:linguagens/data/memory_phases.dart';
import 'package:linguagens/models/difficulty.dart';
import 'package:linguagens/models/mouth_pose.dart';
import 'package:linguagens/widgets/mouth_view.dart';

/// Fácil e Médio têm 8 fases (5 originais + Higiene, Emoções, Transportes);
/// Difícil tem só 7 porque "Transportes" já existia lá e não duplicamos.
const _expectedPhaseCounts = {
  Difficulty.easy: 8,
  Difficulty.medium: 8,
  Difficulty.hard: 7,
};

void main() {
  group('Jogo da Memória', () {
    for (final difficulty in Difficulty.values) {
      test('${difficulty.label}: ${_expectedPhaseCounts[difficulty]} fases com ${difficulty.memoryPairs} pares únicos', () {
        final phases = kMemoryPhases[difficulty]!;
        expect(phases, hasLength(_expectedPhaseCounts[difficulty]!));
        expect(difficulty.memoryColumns * difficulty.memoryRows, difficulty.memoryPairs * 2);

        for (final phase in phases) {
          expect(phase.items, hasLength(difficulty.memoryPairs), reason: phase.title);
          final ids = phase.items.map((i) => i.id).toSet();
          expect(ids, hasLength(phase.items.length), reason: '${phase.title}: ids repetidos');
        }
      });
    }

    test('cards de 12 / 16 / 20', () {
      expect(Difficulty.easy.memoryPairs * 2, 12);
      expect(Difficulty.medium.memoryPairs * 2, 16);
      expect(Difficulty.hard.memoryPairs * 2, 20);
    });

    test('todo PNG referenciado existe', () {
      for (final phases in kMemoryPhases.values) {
        for (final phase in phases) {
          for (final item in phase.items) {
            final path = item.imagePath;
            if (path != null) {
              expect(File(path).existsSync(), isTrue, reason: path);
            }
          }
        }
      }
    });
  });

  group('Complete a Palavra', () {
    test('lacunas: 2 / 4 / 6', () {
      expect(Difficulty.easy.missingLetters, 2);
      expect(Difficulty.medium.missingLetters, 4);
      expect(Difficulty.hard.missingLetters, 6);
    });

    for (final difficulty in Difficulty.values) {
      test('${difficulty.label}: ${_expectedPhaseCounts[difficulty]} fases, lacunas sempre jogáveis', () {
        final phases = kCompletionPhases[difficulty]!;
        expect(phases, hasLength(_expectedPhaseCounts[difficulty]!));

        for (final phase in phases) {
          expect(phase.words, isNotEmpty);
          for (final word in phase.words) {
            // Comportamental, não aritmético: o controller decide sozinho o
            // nº de lacunas de cada palavra (CompletionGameController._
            // startWord reduz o teto da dificuldade pra palavras curtas, tipo
            // "Uva" no Fácil) — então testamos o resultado real em vez de
            // recalcular a fórmula aqui e arriscar os dois divergirem.
            final controller = CompletionGameController(
              words: [word],
              missingLetters: difficulty.missingLetters,
            )..startPhase();

            final blanks = controller.slots.where((s) => s.isBlank).length;
            final visible = controller.slots.length - blanks;
            expect(blanks, greaterThanOrEqualTo(1), reason: '${word.name}: nenhuma lacuna pra jogar');
            expect(blanks, lessThanOrEqualTo(difficulty.missingLetters),
                reason: '${word.name}: mais lacunas do que o nível permite');
            expect(visible, greaterThanOrEqualTo(2),
                reason: '${word.name}: sobraria menos de 2 letras à vista');
          }
        }
      });
    }
  });

  group('Sons das Letras', () {
    test('alfabeto inteiro, em ordem: Fácil A–I, Médio J–R, Difícil S–Z', () {
      String letters(Difficulty d) => kLetterPhases[d]!.map((p) => p.letter).join();
      expect(letters(Difficulty.easy), 'ABCDEFGHI');
      expect(letters(Difficulty.medium), 'JKLMNOPQR');
      expect(letters(Difficulty.hard), 'STUVWXYZ');
    });

    test('vídeo de cada letra segue a convenção de nome', () {
      for (final phases in kLetterPhases.values) {
        for (final phase in phases) {
          expect(phase.videoPath, 'assets/videos/letters/${phase.letter.toLowerCase()}.mp4');
        }
      }
    });

    test('pasta dos vídeos existe e está declarada no pubspec', () {
      expect(Directory('assets/videos/letters').existsSync(), isTrue);
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/videos/letters/'));
    });

    test('todo vídeo na pasta é de uma letra (nome errado nunca seria achado)', () {
      final expected = {
        for (final phases in kLetterPhases.values)
          for (final phase in phases) phase.videoPath,
      };
      final files = Directory('assets/videos/letters')
          .listSync()
          .whereType<File>()
          .map((f) => f.path.replaceAll(r'\', '/'))
          .where((p) => !p.endsWith('.gitkeep'));
      for (final path in files) {
        expect(expected, contains(path), reason: '$path não corresponde a nenhuma letra (use a.mp4 ... z.mp4)');
      }
    });

    test('cada letra tem 2 ou 3 palavras de exemplo diferentes que contêm a letra', () {
      for (final phases in kLetterPhases.values) {
        for (final phase in phases) {
          expect(phase.words.length, inInclusiveRange(2, 3), reason: phase.title);
          expect(phase.words.map((w) => w.id).toSet(), hasLength(phase.words.length), reason: phase.title);
          for (final word in phase.words) {
            expect(
              word.name.split('').any((char) => isSameLetter(char, phase.letter)),
              isTrue,
              reason: '${word.name} não tem a letra ${phase.letter}',
            );
          }
        }
      }
    });

    test('toda letra menos o H tem áudio (o H não tem som)', () {
      for (final phases in kLetterPhases.values) {
        for (final phase in phases) {
          expect(File(phase.audioPath).existsSync(), phase.letter != 'H', reason: phase.audioPath);
        }
      }
    });

    test('linha do tempo da boquinha começa e termina em repouso, em ordem', () {
      for (final phases in kLetterPhases.values) {
        for (final phase in phases) {
          final keyframes = phase.keyframes;
          expect(keyframes.first.at, 0, reason: phase.title);
          expect(keyframes.last.at, 1, reason: phase.title);
          expect(keyframes.first.pose, same(MouthPose.rest), reason: phase.title);
          expect(keyframes.last.pose, same(MouthPose.rest), reason: phase.title);
          for (var i = 1; i < keyframes.length; i++) {
            expect(keyframes[i].at, greaterThan(keyframes[i - 1].at), reason: phase.title);
          }
        }
      }
    });

    test('foto da boquinha existe e está declarada no pubspec', () {
      // Os pontos dos lábios em mouth_view.dart foram marcados nesta foto
      // (3287x2191): trocar o arquivo exige marcar de novo.
      expect(File(kMouthPhotoPath).existsSync(), isTrue, reason: kMouthPhotoPath);
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/images/mouth/'));
    });

    test('pastas de áudio existem e estão declaradas no pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final folder in const ['assets/audio/letters', 'assets/audio/words']) {
        expect(Directory(folder).existsSync(), isTrue, reason: folder);
        expect(pubspec, contains('- $folder/'));
      }
    });

    test('todo áudio nas pastas é de uma letra ou palavra de exemplo (nome errado nunca seria achado)', () {
      final expected = {
        for (final phases in kLetterPhases.values)
          for (final phase in phases) ...[
            phase.audioPath,
            for (final word in phase.words) wordAudioPath(word),
          ],
      };
      for (final folder in const ['assets/audio/letters', 'assets/audio/words']) {
        final files = Directory(folder)
            .listSync()
            .whereType<File>()
            .map((f) => f.path.replaceAll(r'\', '/'))
            .where((p) => !p.endsWith('.gitkeep'));
        for (final path in files) {
          expect(expected, contains(path), reason: '$path não corresponde a nenhuma letra/palavra');
        }
      }
    });
  });
}
