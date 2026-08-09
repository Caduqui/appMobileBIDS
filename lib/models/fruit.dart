class Fruit {
  final String id;
  final String name;
  final String imagePath;

  const Fruit({
    required this.id,
    required this.name,
    required this.imagePath,
  });
}

/// Catálogo das 8 frutas da Fase 1.
/// OBS: "abacaxi" foi assumido como a 8ª fruta para fechar os pares
/// (você citou 7 no pedido original) — troque se preferir outra.
const List<Fruit> kPhase1Fruits = [
  Fruit(id: 'maca', name: 'Maçã', imagePath: 'assets/fruits/maca.png'),
  Fruit(id: 'morango', name: 'Morango', imagePath: 'assets/fruits/morango.png'),
  Fruit(id: 'banana', name: 'Banana', imagePath: 'assets/fruits/banana.png'),
  Fruit(id: 'laranja', name: 'Laranja', imagePath: 'assets/fruits/laranja.png'),
  Fruit(id: 'melancia', name: 'Melancia', imagePath: 'assets/fruits/melancia.png'),
  Fruit(id: 'uva', name: 'Uva', imagePath: 'assets/fruits/uva.png'),
  Fruit(id: 'melao', name: 'Melão', imagePath: 'assets/fruits/melao.png'),
  Fruit(id: 'abacaxi', name: 'Abacaxi', imagePath: 'assets/fruits/abacaxi.png'),
];
