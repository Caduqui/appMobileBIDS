import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:linguagens/controllers/completion_game_controller.dart';
import 'package:linguagens/data/word_catalog.dart';
import 'package:linguagens/models/completion_models.dart';

CompletionGameController _controller({int missing = 4}) => CompletionGameController(
      words: [Words.melancia, Words.maca],
      missingLetters: missing,
      random: Random(1),
    );

/// Resolve a palavra atual tocando sempre a letra certa.
void _solveCurrentWord(CompletionGameController c) {
  while (c.status == CompletionStatus.playing) {
    final expected = c.slots[c.selectedSlot].char;
    final tile = c.tiles.firstWhere((t) => !t.used && t.letter == expected);
    c.onTileTap(tile);
  }
}

void main() {
  test('esconde exatamente N letras e a bandeja tem elas + extras', () {
    final c = _controller(missing: 4)..startPhase();

    final blanks = c.slots.where((s) => s.isBlank).toList();
    expect(blanks, hasLength(4));
    expect(c.slots.where((s) => !s.isBlank).every((s) => s.isFilled), isTrue);
    expect(c.tiles, hasLength(4 + c.extraLetters));

    // Cada letra faltando tem uma peça correspondente na bandeja.
    final trayLetters = c.tiles.map((t) => t.letter).toList();
    for (final s in blanks) {
      expect(trayLetters.remove(s.char), isTrue);
    }
    // As sobras nunca pertencem à palavra.
    for (final extra in trayLetters) {
      expect('MELANCIA'.contains(extra), isFalse);
    }
  });

  test('nunca esconde letra acentuada', () {
    final c = CompletionGameController(
      words: [Words.maca],
      missingLetters: 2,
      random: Random(7),
    )..startPhase();

    for (final s in c.slots.where((s) => s.isBlank)) {
      expect(isBlankableLetter(s.char), isTrue);
    }
    // "Maçã": só M e A podem sumir; Ç e Ã ficam.
    expect(c.slots[2].isBlank, isFalse);
    expect(c.slots[3].isBlank, isFalse);
  });

  test('letra errada não preenche e avisa', () {
    final c = _controller()..startPhase();
    var wrongCalls = 0;
    c.onWrongLetter = () => wrongCalls++;

    final expected = c.slots[c.selectedSlot].char;
    final wrong = c.tiles.firstWhere((t) => t.letter != expected);
    c.onTileTap(wrong);

    expect(wrongCalls, 1);
    expect(c.tiles.every((t) => !t.used), isTrue);
    expect(c.slots.where((s) => s.isBlank && s.isFilled), isEmpty);
    expect(c.status, CompletionStatus.playing);
  });

  test('tocar numa lacuna escolhe onde a letra vai', () {
    final c = _controller()..startPhase();
    final blankIndexes = [
      for (var i = 0; i < c.slots.length; i++)
        if (c.slots[i].isBlank) i,
    ];
    final target = blankIndexes.last;

    c.onSlotTap(target);
    expect(c.selectedSlot, target);

    // Tocar numa letra que já estava à mostra não muda a seleção.
    final shown = c.slots.indexWhere((s) => !s.isBlank);
    c.onSlotTap(shown);
    expect(c.selectedSlot, target);

    final tile = c.tiles.firstWhere((t) => t.letter == c.slots[target].char);
    c.onTileTap(tile);
    expect(c.slots[target].isFilled, isTrue);
  });

  test('completar a palavra, avançar e terminar a fase', () {
    final c = _controller()..startPhase();
    var solved = 0;
    c.onWordSolved = () => solved++;

    _solveCurrentWord(c);
    expect(c.status, CompletionStatus.wordSolved);
    expect(c.slots.every((s) => s.isFilled), isTrue);

    // Com a palavra resolvida, tocar em letras não faz nada.
    c.onTileTap(c.tiles.first);

    c.nextWord();
    expect(c.wordIndex, 1);
    expect(c.status, CompletionStatus.playing);

    _solveCurrentWord(c);
    expect(c.status, CompletionStatus.phaseCompleted);
    expect(solved, 2);

    c.startPhase();
    expect(c.wordIndex, 0);
    expect(c.status, CompletionStatus.playing);
  });

  test('letras repetidas: qualquer peça igual serve', () {
    // "BANANA" com 4 lacunas costuma esconder vários A/N.
    final c = CompletionGameController(
      words: [Words.banana],
      missingLetters: 4,
      random: Random(3),
    )..startPhase();
    _solveCurrentWord(c);
    expect(c.status, CompletionStatus.phaseCompleted);
  });
}
