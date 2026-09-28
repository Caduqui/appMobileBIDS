import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linguagens/controllers/completion_game_controller.dart';
import 'package:linguagens/data/completion_phases.dart';
import 'package:linguagens/data/memory_phases.dart';
import 'package:linguagens/models/difficulty.dart';

void main() {
  group('Jogo da Memória', () {
    for (final difficulty in Difficulty.values) {
      test('${difficulty.label}: 5 fases com ${difficulty.memoryPairs} pares únicos', () {
        final phases = kMemoryPhases[difficulty]!;
        expect(phases, hasLength(5));
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
      test('${difficulty.label}: 5 fases, palavras comportam as lacunas', () {
        final phases = kCompletionPhases[difficulty]!;
        expect(phases, hasLength(5));

        for (final phase in phases) {
          expect(phase.words, isNotEmpty);
          for (final word in phase.words) {
            final chars = word.name.toUpperCase().split('');
            final blankable = chars.where(isBlankableLetter).length;
            expect(blankable, greaterThanOrEqualTo(difficulty.missingLetters), reason: word.name);
            expect(chars.length, greaterThanOrEqualTo(difficulty.missingLetters + 2),
                reason: '${word.name}: sobraria menos de 2 letras à vista');
          }
        }
      });
    }
  });
}
