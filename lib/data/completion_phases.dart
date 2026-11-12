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
/// com acento nunca ficam faltando (aparecem como dica). O nº de lacunas de
/// `difficulty.missingLetters` é um teto, não obrigatório — o
/// CompletionGameController reduz sozinho pra palavras curtas demais (ex.:
/// "Uva" no Fácil), então não precisa escolher só palavras compridas pra
/// "caber" na dificuldade; só evite palavras com só 1 letra sem acento (aí
/// não sobraria nenhuma lacuna pra jogar).
const Map<Difficulty, List<CompletionPhase>> kCompletionPhases = {
  Difficulty.easy: [
    // Palavras curtas de propósito: são as primeiras fases que a criança vê
    // no Complete a Palavra, então além de poucas lacunas (regra geral do
    // Fácil) elas também precisam ser as palavras mais curtas do vocabulário
    // de cada tema. Ex.: "Uva/Limão/Melão" aqui em vez de "Banana/Abacaxi/
    // Laranja" (que são mais longas e ficam pras fases de Memória do Fácil).
    // "Uva" tem só 3 letras: o controller reduz sozinho pra 1 lacuna em vez
    // das 2 padrão do Fácil, senão sobraria menos de 2 letras visíveis (ver
    // CompletionGameController._startWord). "Maçã" foi trocada por ela: pra
    // quem ainda não lê/escreve, acentuação (çã) é complexidade a mais que
    // não serve pro nível mais fácil.
    CompletionPhase(
      title: 'Frutas',
      words: [Words.uva, Words.limao, Words.melao],
    ),
    CompletionPhase(
      title: 'Animais',
      words: [Words.gato, Words.pato, Words.vaca],
    ),
    CompletionPhase(
      title: 'Objetos escolares',
      words: [Words.lapis, Words.livro, Words.lupa],
    ),
    CompletionPhase(
      title: 'Brinquedos',
      words: [Words.bola, Words.pipa, Words.dado],
    ),
    CompletionPhase(
      title: 'Comidas',
      words: [Words.bolo, Words.leite, Words.pizza],
    ),
    CompletionPhase(
      title: 'Higiene',
      words: [Words.escova, Words.pente, Words.xampu],
    ),
    CompletionPhase(
      title: 'Emoções',
      words: [Words.medo, Words.calmo, Words.bravo],
    ),
    CompletionPhase(
      title: 'Transportes',
      words: [Words.trem, Words.moto, Words.carro],
    ),
  ],
  Difficulty.medium: [
    CompletionPhase(
      title: 'Frutas',
      words: [Words.morango, Words.abacate, Words.melancia],
    ),
    CompletionPhase(
      title: 'Animais',
      words: [Words.elefante, Words.girafa, Words.cachorro],
    ),
    CompletionPhase(
      title: 'Objetos escolares',
      words: [Words.mochila, Words.tesoura, Words.caderno],
    ),
    CompletionPhase(
      title: 'Brinquedos',
      words: [Words.carrinho, Words.ursinho, Words.presente],
    ),
    CompletionPhase(
      title: 'Comidas',
      words: [Words.sorvete, Words.biscoito, Words.pipoca],
    ),
    CompletionPhase(
      title: 'Higiene',
      words: [Words.esponja, Words.espelho, Words.sabonete],
    ),
    CompletionPhase(
      title: 'Emoções',
      words: [Words.cansado, Words.animado, Words.confuso],
    ),
    CompletionPhase(
      title: 'Transportes',
      words: [Words.onibus, Words.foguete, Words.bicicleta],
    ),
  ],
  Difficulty.hard: [
    CompletionPhase(
      title: 'Frutas e legumes',
      words: [Words.tangerina, Words.brocolis, Words.berinjela],
    ),
    CompletionPhase(
      title: 'Animais',
      words: [Words.crocodilo, Words.borboleta, Words.dinossauro],
    ),
    CompletionPhase(
      title: 'Escola e ciência',
      words: [Words.computador, Words.calendario, Words.microscopio],
    ),
    CompletionPhase(
      title: 'Transportes',
      words: [Words.bicicleta, Words.helicoptero, Words.caminhao],
    ),
    CompletionPhase(
      title: 'Comidas',
      words: [Words.chocolate, Words.hamburguer, Words.panqueca],
    ),
    // Sem "Transportes" aqui: o tema já existe acima.
    CompletionPhase(
      title: 'Higiene',
      words: [Words.banheira, Words.chuveiro, Words.barbeador],
    ),
    CompletionPhase(
      title: 'Emoções',
      words: [Words.surpreso, Words.envergonhado, Words.entediado],
    ),
  ],
};
