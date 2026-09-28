/// Uma palavra do vocabulário (fruta, animal, objeto escolar...) com a sua
/// ilustração. A ilustração é um PNG ([imagePath]) ou, na falta dele, um
/// [emoji]. Para trocar um emoji por arte própria basta preencher o
/// `imagePath` do item em `data/word_catalog.dart` — os jogos não mudam.
class WordItem {
  final String id;
  final String name;
  final String? imagePath;
  final String? emoji;

  const WordItem({
    required this.id,
    required this.name,
    this.imagePath,
    this.emoji,
  }) : assert(imagePath != null || emoji != null,
            'WordItem precisa de imagePath ou emoji');
}
