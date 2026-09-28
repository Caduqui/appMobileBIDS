import '../models/difficulty.dart';
import '../models/word_item.dart';
import 'word_catalog.dart';

class MemoryPhase {
  final String title;
  final List<WordItem> items;

  const MemoryPhase({required this.title, required this.items});
}

/// Fases do Jogo da Memória. Cada fase precisa ter exatamente
/// `difficulty.memoryPairs` itens (6 / 8 / 10) — o teste em
/// test/game_data_test.dart confere isso.
const Map<Difficulty, List<MemoryPhase>> kMemoryPhases = {
  Difficulty.easy: [
    MemoryPhase(title: 'Frutas', items: [
      Words.maca, Words.banana, Words.uva, Words.laranja, Words.morango, Words.abacaxi,
    ]),
    MemoryPhase(title: 'Animais da fazenda', items: [
      Words.vaca, Words.porco, Words.galinha, Words.cavalo, Words.ovelha, Words.pato,
    ]),
    MemoryPhase(title: 'Objetos escolares', items: [
      Words.lapis, Words.livro, Words.mochila, Words.tesoura, Words.caderno, Words.regua,
    ]),
    MemoryPhase(title: 'Brinquedos', items: [
      Words.bola, Words.ursinho, Words.balao, Words.dado, Words.carrinho, Words.pipa,
    ]),
    MemoryPhase(title: 'Comidas', items: [
      Words.pao, Words.ovo, Words.leite, Words.bolo, Words.sorvete, Words.pizza,
    ]),
  ],
  Difficulty.medium: [
    // Fase 1 original do jogo (8 frutas).
    MemoryPhase(title: 'Frutas', items: [
      Words.maca, Words.morango, Words.banana, Words.laranja,
      Words.melancia, Words.uva, Words.melao, Words.abacaxi,
    ]),
    MemoryPhase(title: 'Animais da selva', items: [
      Words.leao, Words.elefante, Words.macaco, Words.girafa,
      Words.zebra, Words.tigre, Words.urso, Words.cobra,
    ]),
    MemoryPhase(title: 'Objetos escolares', items: [
      Words.lapis, Words.livro, Words.mochila, Words.tesoura,
      Words.caderno, Words.regua, Words.caneta, Words.lupa,
    ]),
    MemoryPhase(title: 'Brinquedos', items: [
      Words.bola, Words.ursinho, Words.balao, Words.dado,
      Words.carrinho, Words.pipa, Words.presente, Words.trem,
    ]),
    MemoryPhase(title: 'Comidas', items: [
      Words.pao, Words.queijo, Words.pipoca, Words.batata,
      Words.mel, Words.bolo, Words.ovo, Words.leite,
    ]),
  ],
  Difficulty.hard: [
    MemoryPhase(title: 'Frutas e legumes', items: [
      Words.maca, Words.banana, Words.uva, Words.morango, Words.cenoura,
      Words.tomate, Words.milho, Words.abacate, Words.limao, Words.cereja,
    ]),
    MemoryPhase(title: 'Bichos', items: [
      Words.cachorro, Words.gato, Words.coelho, Words.sapo, Words.rato,
      Words.borboleta, Words.abelha, Words.coruja, Words.pinguim, Words.jacare,
    ]),
    MemoryPhase(title: 'Animais do mar', items: [
      Words.peixe, Words.baleia, Words.polvo, Words.tubarao, Words.caranguejo,
      Words.golfinho, Words.tartaruga, Words.lula, Words.camarao, Words.concha,
    ]),
    MemoryPhase(title: 'Transportes', items: [
      Words.carro, Words.onibus, Words.aviao, Words.barco, Words.trem,
      Words.foguete, Words.bicicleta, Words.moto, Words.helicoptero, Words.caminhao,
    ]),
    MemoryPhase(title: 'Comidas', items: [
      Words.hamburguer, Words.sanduiche, Words.espaguete, Words.chocolate, Words.biscoito,
      Words.panqueca, Words.pirulito, Words.rosquinha, Words.sorvete, Words.pizza,
    ]),
  ],
};
