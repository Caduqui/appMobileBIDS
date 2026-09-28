/// Uma posição da palavra. Letras que já vêm à mostra nascem com
/// `isFilled = true`; as "faltando" nascem vazias e o jogador preenche.
class LetterSlot {
  final String char; // sempre maiúscula
  final bool isBlank;
  final bool isFilled;

  const LetterSlot({
    required this.char,
    required this.isBlank,
    required this.isFilled,
  });

  LetterSlot copyWith({bool? isFilled}) {
    return LetterSlot(
      char: char,
      isBlank: isBlank,
      isFilled: isFilled ?? this.isFilled,
    );
  }
}

/// Uma letra disponível na bandeja. `id` separa duas letras iguais
/// (ex.: dois "A") para a UI saber qual delas já foi usada.
class LetterTile {
  final int id;
  final String letter;
  final bool used;

  const LetterTile({required this.id, required this.letter, this.used = false});

  LetterTile copyWith({bool? used}) {
    return LetterTile(id: id, letter: letter, used: used ?? this.used);
  }
}

enum CompletionStatus {
  playing,
  wordSolved, // palavra completa, esperando "Próxima"
  phaseCompleted, // última palavra da fase completa
}
