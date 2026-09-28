import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/completion_models.dart';
import '../models/word_item.dart';

/// Só letras de A a Z podem ficar faltando. Letras acentuadas (Ã, Ç, É...)
/// sempre aparecem como dica — a criança ainda vê o acento, mas não precisa
/// achar "Ã" numa bandeja de letras simples.
bool isBlankableLetter(String char) => RegExp(r'^[A-Z]$').hasMatch(char);

class CompletionGameController extends ChangeNotifier {
  CompletionGameController({
    required this._words,
    required this._missingLetters,
    this.extraLetters = 3,
    Random? random,
  }) : _random = random ?? Random();

  final List<WordItem> _words;
  final int _missingLetters;
  final Random _random;

  /// Letras "de enfeite" na bandeja, que não pertencem à palavra.
  final int extraLetters;

  int wordIndex = 0;
  List<LetterSlot> slots = [];
  List<LetterTile> tiles = [];
  int selectedSlot = -1;
  CompletionStatus status = CompletionStatus.playing;

  /// Ganchos pra tela disparar animações/efeitos sem o controller conhecer a UI.
  VoidCallback? onWrongLetter;
  VoidCallback? onWordSolved;

  int get wordCount => _words.length;
  WordItem get currentWord => _words[wordIndex];
  bool get isLastWord => wordIndex == _words.length - 1;

  void startPhase() {
    wordIndex = 0;
    _startWord();
    notifyListeners();
  }

  void nextWord() {
    if (status != CompletionStatus.wordSolved) return;
    wordIndex++;
    _startWord();
    notifyListeners();
  }

  void _startWord() {
    final chars = currentWord.name.toUpperCase().split('');

    final candidates = [
      for (var i = 0; i < chars.length; i++)
        if (isBlankableLetter(chars[i])) i,
    ]..shuffle(_random);
    final blanks = candidates.take(_missingLetters).toSet();

    slots = [
      for (var i = 0; i < chars.length; i++)
        LetterSlot(
          char: chars[i],
          isBlank: blanks.contains(i),
          isFilled: !blanks.contains(i),
        ),
    ];

    final letters = [
      for (final i in blanks) chars[i],
      ..._pickExtraLetters(chars),
    ]..shuffle(_random);
    tiles = [
      for (var i = 0; i < letters.length; i++) LetterTile(id: i, letter: letters[i]),
    ];

    selectedSlot = _firstEmptySlot();
    status = CompletionStatus.playing;
  }

  /// Sorteia letras que não aparecem na palavra, pra nunca existir um "A"
  /// sobrando que pareça certo mas não serve.
  List<String> _pickExtraLetters(List<String> wordChars) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final pool = alphabet.split('').where((l) => !wordChars.contains(l)).toList()
      ..shuffle(_random);
    return pool.take(extraLetters).toList();
  }

  int _firstEmptySlot() => slots.indexWhere((s) => s.isBlank && !s.isFilled);

  /// Escolhe qual lacuna receberá a próxima letra.
  void onSlotTap(int index) {
    if (status != CompletionStatus.playing) return;
    final slot = slots[index];
    if (!slot.isBlank || slot.isFilled) return;
    selectedSlot = index;
    notifyListeners();
  }

  /// Coloca a letra na lacuna selecionada. Se estiver certa, ela fica;
  /// se estiver errada, nada muda além do aviso [onWrongLetter] — a criança
  /// tenta de novo sem perder progresso.
  void onTileTap(LetterTile tile) {
    if (status != CompletionStatus.playing) return;
    if (tile.used || selectedSlot < 0) return;

    if (slots[selectedSlot].char != tile.letter) {
      onWrongLetter?.call();
      return;
    }

    slots = [
      for (var i = 0; i < slots.length; i++)
        i == selectedSlot ? slots[i].copyWith(isFilled: true) : slots[i],
    ];
    tiles = [
      for (final t in tiles) t.id == tile.id ? t.copyWith(used: true) : t,
    ];

    selectedSlot = _nextEmptySlotAfter(selectedSlot);
    if (selectedSlot < 0) {
      status = isLastWord ? CompletionStatus.phaseCompleted : CompletionStatus.wordSolved;
      onWordSolved?.call();
    }
    notifyListeners();
  }

  /// Próxima lacuna vazia à direita; se não houver, volta ao começo.
  int _nextEmptySlotAfter(int index) {
    for (var i = index + 1; i < slots.length; i++) {
      if (slots[i].isBlank && !slots[i].isFilled) return i;
    }
    return _firstEmptySlot();
  }
}
