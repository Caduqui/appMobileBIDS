import '../models/difficulty.dart';
import '../models/word_item.dart';
import 'word_catalog.dart';

class CompletionPhase {
  final String title;
  final List<WordItem> words;

  const CompletionPhase({required this.title, required this.words});
}

/// Fases do Complete a Palavra: cada fase tem 3 palavras, jogadas em sequência.
///
/// Regra pra escolher palavras (conferida em test/game_data_test.dart): letras
/// com acento nunca ficam faltando (aparecem como dica), então a palavra
/// precisa ter letras "de A a Z" suficientes pra esconder
/// `difficulty.missingLetters` e ainda sobrar pelo menos 2 letras à vista.
const Map<Difficulty, List<CompletionPhase>> kCompletionPhases = {
  Difficulty.easy: [
    CompletionPhase(title: 'Frutas', words: [Words.banana, Words.abacaxi, Words.laranja]),
    CompletionPhase(title: 'Animais', words: [Words.gato, Words.pato, Words.vaca]),
    CompletionPhase(title: 'Objetos escolares', words: [Words.lapis, Words.livro, Words.caneta]),
    CompletionPhase(title: 'Brinquedos', words: [Words.bola, Words.pipa, Words.dado]),
    CompletionPhase(title: 'Comidas', words: [Words.bolo, Words.leite, Words.pizza]),
  ],
  Difficulty.medium: [
    CompletionPhase(title: 'Frutas', words: [Words.morango, Words.abacate, Words.melancia]),
    CompletionPhase(title: 'Animais', words: [Words.elefante, Words.girafa, Words.cachorro]),
    CompletionPhase(title: 'Objetos escolares', words: [Words.mochila, Words.tesoura, Words.caderno]),
    CompletionPhase(title: 'Brinquedos', words: [Words.carrinho, Words.ursinho, Words.presente]),
    CompletionPhase(title: 'Comidas', words: [Words.sorvete, Words.biscoito, Words.pipoca]),
  ],
  Difficulty.hard: [
    CompletionPhase(title: 'Frutas e legumes', words: [Words.tangerina, Words.brocolis, Words.berinjela]),
    CompletionPhase(title: 'Animais', words: [Words.crocodilo, Words.borboleta, Words.dinossauro]),
    CompletionPhase(title: 'Escola e ciência', words: [Words.computador, Words.calendario, Words.microscopio]),
    CompletionPhase(title: 'Transportes', words: [Words.bicicleta, Words.helicoptero, Words.caminhao]),
    CompletionPhase(title: 'Comidas', words: [Words.chocolate, Words.hamburguer, Words.panqueca]),
  ],
};
