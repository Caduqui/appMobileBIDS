/// Níveis de dificuldade compartilhados por todos os minigames.
///
/// Cada minigame lê daqui só o que lhe interessa:
/// - Jogo da Memória usa [memoryColumns] x [memoryRows] (sempre em retrato,
///   pensando em celular em pé) e [previewSeconds].
/// - Complete a Palavra usa [missingLetters].
enum Difficulty {
  easy(
    label: 'Fácil',
    memoryColumns: 3,
    memoryRows: 4, // 12 cards = 6 pares
    previewSeconds: 4,
    missingLetters: 2,
  ),
  medium(
    label: 'Médio',
    memoryColumns: 4,
    memoryRows: 4, // 16 cards = 8 pares
    previewSeconds: 5,
    missingLetters: 4,
  ),
  hard(
    label: 'Difícil',
    memoryColumns: 4,
    memoryRows: 5, // 20 cards = 10 pares
    previewSeconds: 6,
    missingLetters: 6,
  );

  const Difficulty({
    required this.label,
    required this.memoryColumns,
    required this.memoryRows,
    required this.previewSeconds,
    required this.missingLetters,
  });

  final String label;
  final int memoryColumns;
  final int memoryRows;
  final int previewSeconds;
  final int missingLetters;

  int get memoryPairs => memoryColumns * memoryRows ~/ 2;
}
