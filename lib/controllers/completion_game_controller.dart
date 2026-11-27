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

  /// Nº de lacunas "alvo" da dificuldade. É um teto, não um valor fixo: uma
  /// palavra curta demais pra esse nº (ex.: "Uva" no Fácil, que pede 2) usa
  /// menos lacunas em vez de ficar sem jogo ou sem letra visível — ver
  /// `_startWord`.
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

  /// Letra certa encaixou e a palavra ainda não acabou (quando acaba, quem
  /// avisa é só o [onWordSolved], pra não tocar dois sons juntos).
  VoidCallback? onLetterPlaced;

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

    // Nunca esconde mais letras do que a palavra comporta deixando pelo
    // menos 2 à vista. Pra palavras do tamanho normal do vocabulário isso
    // nunca entra em ação (maxMissingForWord fica bem acima de
    // _missingLetters); só limita o caso de uma palavra bem curta, tipo
    // "Uva" (3 letras) no Fácil, que pediria 2 lacunas mas só comporta 1.
    final maxMissingForWord = (chars.length - 2).clamp(1, candidates.length);
    final missingCount = _missingLetters < maxMissingForWord
        ? _missingLetters
        : maxMissingForWord;
    final blanks = candidates.take(missingCount).toSet();

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
      for (var i = 0; i < letters.length; i++)
        LetterTile(id: i, letter: letters[i]),
    ];

    selectedSlot = _firstEmptySlot();
    status = CompletionStatus.playing;
  }

  /// Sorteia letras que não aparecem na palavra, pra nunca existir um "A"
  /// sobrando que pareça certo mas não serve.
  List<String> _pickExtraLetters(List<String> wordChars) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final pool =
        alphabet.split('').where((l) => !wordChars.contains(l)).toList()
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
      status = isLastWord
          ? CompletionStatus.phaseCompleted
          : CompletionStatus.wordSolved;
      onWordSolved?.call();
    } else {
      onLetterPlaced?.call();
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
