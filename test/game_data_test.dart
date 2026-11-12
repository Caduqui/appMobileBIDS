import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linguagens/controllers/completion_game_controller.dart';
import 'package:linguagens/data/completion_phases.dart';
import 'package:linguagens/data/memory_phases.dart';
import 'package:linguagens/models/difficulty.dart';

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
}
