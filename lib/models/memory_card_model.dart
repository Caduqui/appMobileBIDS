import 'fruit.dart';

/// Estado individual de cada carta.
/// mismatchError é um estado próprio (não reaproveita faceUp) para que a UI
/// fique "burra": ela só olha o estado e decide a animação, sem precisar
/// saber se estamos no meio de uma checagem de par.
enum CardState { faceDown, faceUp, matched, mismatchError }

class MemoryCardModel {
  final String cardId;
  final Fruit fruit;
  final CardState state;

  const MemoryCardModel({
    required this.cardId,
    required this.fruit,
    this.state = CardState.faceDown,
  });

  /// Imutabilidade é essencial aqui: o Flutter decide se anima o flip
  /// comparando o widget antigo com o novo. Se mutássemos `state` direto
  /// no mesmo objeto, "antigo" e "novo" seriam a mesma referência e a
  /// comparação nunca detectaria mudança.
  MemoryCardModel copyWith({CardState? state}) {
    return MemoryCardModel(
      cardId: cardId,
      fruit: fruit,
      state: state ?? this.state,
    );
  }
}