import '../models/word_item.dart';

/// Vocabulário único usado pelos jogos (memória, completar e as palavras
/// de exemplo do Sons das Letras).
/// As 8 frutas originais usam PNG; o resto usa emoji até existir arte própria
/// (é só preencher `imagePath` no item para trocar).
abstract final class Words {
  // ---- Frutas e legumes ----
  static const maca = WordItem(
    id: 'maca',
    name: 'Maçã',
    imagePath: 'assets/fruits/maca.png',
  );
  static const morango = WordItem(
    id: 'morango',
    name: 'Morango',
    imagePath: 'assets/fruits/morango.png',
  );
  static const banana = WordItem(
    id: 'banana',
    name: 'Banana',
    imagePath: 'assets/fruits/banana.png',
  );
  static const laranja = WordItem(
    id: 'laranja',
    name: 'Laranja',
    imagePath: 'assets/fruits/laranja.png',
  );
  static const melancia = WordItem(
    id: 'melancia',
    name: 'Melancia',
    imagePath: 'assets/fruits/melancia.png',
  );
  static const uva = WordItem(
    id: 'uva',
    name: 'Uva',
    imagePath: 'assets/fruits/uva.png',
  );
  static const melao = WordItem(
    id: 'melao',
    name: 'Melão',
    imagePath: 'assets/fruits/melao.png',
  );
  static const abacaxi = WordItem(
    id: 'abacaxi',
    name: 'Abacaxi',
    imagePath: 'assets/fruits/abacaxi.png',
  );
  static const abacate = WordItem(id: 'abacate', name: 'Abacate', emoji: '🥑');
  static const tangerina = WordItem(
    id: 'tangerina',
    name: 'Tangerina',
    emoji: '🍊',
  );
  static const limao = WordItem(id: 'limao', name: 'Limão', emoji: '🍋');
  static const cereja = WordItem(id: 'cereja', name: 'Cereja', emoji: '🍒');
  static const cenoura = WordItem(id: 'cenoura', name: 'Cenoura', emoji: '🥕');
  static const tomate = WordItem(id: 'tomate', name: 'Tomate', emoji: '🍅');
  static const milho = WordItem(id: 'milho', name: 'Milho', emoji: '🌽');
  static const brocolis = WordItem(
    id: 'brocolis',
    name: 'Brócolis',
    emoji: '🥦',
  );
  static const berinjela = WordItem(
    id: 'berinjela',
    name: 'Berinjela',
    emoji: '🍆',
  );

  // ---- Animais da fazenda ----
  static const vaca = WordItem(id: 'vaca', name: 'Vaca', emoji: '🐄');
  static const porco = WordItem(id: 'porco', name: 'Porco', emoji: '🐖');
  static const galinha = WordItem(id: 'galinha', name: 'Galinha', emoji: '🐔');
  static const cavalo = WordItem(id: 'cavalo', name: 'Cavalo', emoji: '🐴');
  static const ovelha = WordItem(id: 'ovelha', name: 'Ovelha', emoji: '🐑');
  static const pato = WordItem(id: 'pato', name: 'Pato', emoji: '🦆');

  // ---- Animais da selva ----
  static const leao = WordItem(id: 'leao', name: 'Leão', emoji: '🦁');
  static const elefante = WordItem(
    id: 'elefante',
    name: 'Elefante',
    emoji: '🐘',
  );
  static const macaco = WordItem(id: 'macaco', name: 'Macaco', emoji: '🐵');
  static const girafa = WordItem(id: 'girafa', name: 'Girafa', emoji: '🦒');
  static const zebra = WordItem(id: 'zebra', name: 'Zebra', emoji: '🦓');
  static const tigre = WordItem(id: 'tigre', name: 'Tigre', emoji: '🐯');
  static const urso = WordItem(id: 'urso', name: 'Urso', emoji: '🐻');
  static const cobra = WordItem(id: 'cobra', name: 'Cobra', emoji: '🐍');

  // ---- Bichos de casa, jardim e floresta ----
  static const cachorro = WordItem(
    id: 'cachorro',
    name: 'Cachorro',
    emoji: '🐶',
  );
  static const gato = WordItem(id: 'gato', name: 'Gato', emoji: '🐱');
  static const coelho = WordItem(id: 'coelho', name: 'Coelho', emoji: '🐰');
  static const sapo = WordItem(id: 'sapo', name: 'Sapo', emoji: '🐸');
  static const rato = WordItem(id: 'rato', name: 'Rato', emoji: '🐭');
  static const borboleta = WordItem(
    id: 'borboleta',
    name: 'Borboleta',
    emoji: '🦋',
  );
  static const abelha = WordItem(id: 'abelha', name: 'Abelha', emoji: '🐝');
  static const coruja = WordItem(id: 'coruja', name: 'Coruja', emoji: '🦉');
  static const pinguim = WordItem(id: 'pinguim', name: 'Pinguim', emoji: '🐧');
  static const jacare = WordItem(id: 'jacare', name: 'Jacaré', emoji: '🐊');
  static const crocodilo = WordItem(
    id: 'crocodilo',
    name: 'Crocodilo',
    emoji: '🐊',
  );
  static const dinossauro = WordItem(
    id: 'dinossauro',
    name: 'Dinossauro',
    emoji: '🦕',
  );

  // ---- Animais do mar ----
  static const peixe = WordItem(id: 'peixe', name: 'Peixe', emoji: '🐟');
  static const baleia = WordItem(id: 'baleia', name: 'Baleia', emoji: '🐳');
  static const polvo = WordItem(id: 'polvo', name: 'Polvo', emoji: '🐙');
  static const tubarao = WordItem(id: 'tubarao', name: 'Tubarão', emoji: '🦈');
  static const caranguejo = WordItem(
    id: 'caranguejo',
    name: 'Caranguejo',
    emoji: '🦀',
  );
  static const golfinho = WordItem(
    id: 'golfinho',
    name: 'Golfinho',
    emoji: '🐬',
  );
  static const tartaruga = WordItem(
    id: 'tartaruga',
    name: 'Tartaruga',
    emoji: '🐢',
  );
  static const lula = WordItem(id: 'lula', name: 'Lula', emoji: '🦑');
  static const camarao = WordItem(id: 'camarao', name: 'Camarão', emoji: '🦐');
  static const concha = WordItem(id: 'concha', name: 'Concha', emoji: '🐚');

  // ---- Objetos escolares ----
  static const lapis = WordItem(id: 'lapis', name: 'Lápis', emoji: '✏️');
  static const livro = WordItem(id: 'livro', name: 'Livro', emoji: '📖');
  static const mochila = WordItem(id: 'mochila', name: 'Mochila', emoji: '🎒');
  static const tesoura = WordItem(id: 'tesoura', name: 'Tesoura', emoji: '✂️');
  static const caderno = WordItem(id: 'caderno', name: 'Caderno', emoji: '📓');
  static const regua = WordItem(id: 'regua', name: 'Régua', emoji: '📏');
  static const caneta = WordItem(
    id: 'caneta',
    name: 'Caneta',
    emoji: '\u{1F58A}️',
  );
  static const lupa = WordItem(id: 'lupa', name: 'Lupa', emoji: '🔍');
  static const computador = WordItem(
    id: 'computador',
    name: 'Computador',
    emoji: '💻',
  );
  static const calendario = WordItem(
    id: 'calendario',
    name: 'Calendário',
    emoji: '📅',
  );
  static const microscopio = WordItem(
    id: 'microscopio',
    name: 'Microscópio',
    emoji: '🔬',
  );

  // ---- Brinquedos ----
  static const bola = WordItem(id: 'bola', name: 'Bola', emoji: '⚽');
  static const ursinho = WordItem(id: 'ursinho', name: 'Ursinho', emoji: '🧸');
  static const balao = WordItem(id: 'balao', name: 'Balão', emoji: '🎈');
  static const dado = WordItem(id: 'dado', name: 'Dado', emoji: '🎲');
  static const carrinho = WordItem(
    id: 'carrinho',
    name: 'Carrinho',
    emoji: '🚗',
  );
  static const pipa = WordItem(id: 'pipa', name: 'Pipa', emoji: '🪁');
  static const presente = WordItem(
    id: 'presente',
    name: 'Presente',
    emoji: '🎁',
  );

  // ---- Transportes ----
  static const carro = WordItem(id: 'carro', name: 'Carro', emoji: '🚗');
  static const onibus = WordItem(id: 'onibus', name: 'Ônibus', emoji: '🚌');
  static const aviao = WordItem(id: 'aviao', name: 'Avião', emoji: '✈️');
  static const barco = WordItem(id: 'barco', name: 'Barco', emoji: '⛵');
  static const trem = WordItem(id: 'trem', name: 'Trem', emoji: '🚂');
  static const foguete = WordItem(id: 'foguete', name: 'Foguete', emoji: '🚀');
  static const bicicleta = WordItem(
    id: 'bicicleta',
    name: 'Bicicleta',
    emoji: '🚲',
  );
  static const moto = WordItem(id: 'moto', name: 'Moto', emoji: '\u{1F3CD}️');
  static const helicoptero = WordItem(
    id: 'helicoptero',
    name: 'Helicóptero',
    emoji: '🚁',
  );
  static const caminhao = WordItem(
    id: 'caminhao',
    name: 'Caminhão',
    emoji: '🚚',
  );

  // ---- Comidas ----
  static const pao = WordItem(id: 'pao', name: 'Pão', emoji: '🍞');
  static const ovo = WordItem(id: 'ovo', name: 'Ovo', emoji: '🥚');
  static const leite = WordItem(id: 'leite', name: 'Leite', emoji: '🥛');
  static const bolo = WordItem(id: 'bolo', name: 'Bolo', emoji: '🎂');
  static const sorvete = WordItem(id: 'sorvete', name: 'Sorvete', emoji: '🍦');
  static const pizza = WordItem(id: 'pizza', name: 'Pizza', emoji: '🍕');
  static const queijo = WordItem(id: 'queijo', name: 'Queijo', emoji: '🧀');
  static const pipoca = WordItem(id: 'pipoca', name: 'Pipoca', emoji: '🍿');
  static const batata = WordItem(id: 'batata', name: 'Batata', emoji: '🍟');
  static const mel = WordItem(id: 'mel', name: 'Mel', emoji: '🍯');
  static const hamburguer = WordItem(
    id: 'hamburguer',
    name: 'Hambúrguer',
    emoji: '🍔',
  );
  static const sanduiche = WordItem(
    id: 'sanduiche',
    name: 'Sanduíche',
    emoji: '🥪',
  );
  static const espaguete = WordItem(
    id: 'espaguete',
    name: 'Espaguete',
    emoji: '🍝',
  );
  static const chocolate = WordItem(
    id: 'chocolate',
    name: 'Chocolate',
    emoji: '🍫',
  );
  static const biscoito = WordItem(
    id: 'biscoito',
    name: 'Biscoito',
    emoji: '🍪',
  );
  static const panqueca = WordItem(
    id: 'panqueca',
    name: 'Panqueca',
    emoji: '🥞',
  );
  static const pirulito = WordItem(
    id: 'pirulito',
    name: 'Pirulito',
    emoji: '🍭',
  );
  static const rosquinha = WordItem(
    id: 'rosquinha',
    name: 'Rosquinha',
    emoji: '🍩',
  );

  // ---- Higiene ----
  static const escova = WordItem(id: 'escova', name: 'Escova', emoji: '🪥');
  static const sabonete = WordItem(
    id: 'sabonete',
    name: 'Sabonete',
    emoji: '🧼',
  );
  static const xampu = WordItem(id: 'xampu', name: 'Xampu', emoji: '🧴');
  static const pente = WordItem(id: 'pente', name: 'Pente', emoji: '🪮');
  static const chuveiro = WordItem(
    id: 'chuveiro',
    name: 'Chuveiro',
    emoji: '🚿',
  );
  static const banheira = WordItem(
    id: 'banheira',
    name: 'Banheira',
    emoji: '🛁',
  );
  static const esponja = WordItem(id: 'esponja', name: 'Esponja', emoji: '🧽');
  static const espelho = WordItem(id: 'espelho', name: 'Espelho', emoji: '🪞');
  static const pia = WordItem(id: 'pia', name: 'Pia', emoji: '🚰');
  static const barbeador = WordItem(
    id: 'barbeador',
    name: 'Barbeador',
    emoji: '🪒',
  );

  // ---- Emoções ----
  static const feliz = WordItem(id: 'feliz', name: 'Feliz', emoji: '😃');
  static const triste = WordItem(id: 'triste', name: 'Triste', emoji: '😢');
  static const bravo = WordItem(id: 'bravo', name: 'Bravo', emoji: '😠');
  static const medo = WordItem(id: 'medo', name: 'Medo', emoji: '😨');
  static const surpreso = WordItem(
    id: 'surpreso',
    name: 'Surpreso',
    emoji: '😲',
  );
  static const cansado = WordItem(id: 'cansado', name: 'Cansado', emoji: '😴');
  static const animado = WordItem(id: 'animado', name: 'Animado', emoji: '🤩');
  static const calmo = WordItem(id: 'calmo', name: 'Calmo', emoji: '😌');
  static const envergonhado = WordItem(
    id: 'envergonhado',
    name: 'Envergonhado',
    emoji: '😳',
  );
  static const confuso = WordItem(id: 'confuso', name: 'Confuso', emoji: '😕');
  static const entediado = WordItem(
    id: 'entediado',
    name: 'Entediado',
    emoji: '🥱',
  );

  // ---- Sons das Letras ----
  // Palavras de exemplo dos slides do Método das Boquinhas (as que não
  // existiam acima). O `id` é o nome do áudio em assets/audio/words/ — não
  // renomeie um sem renomear o outro. Ver data/letter_phases.dart.
  static const amor = WordItem(id: 'amor', name: 'Amor', emoji: '❤️');
  static const telhado = WordItem(id: 'telhado', name: 'Telhado', emoji: '🏘️');
  static const porta = WordItem(id: 'porta', name: 'Porta', emoji: '🚪');
  static const ema = WordItem(id: 'ema', name: 'Ema', emoji: '🐦');
  static const boneca = WordItem(id: 'boneca', name: 'Boneca', emoji: '🪆');
  static const cafe = WordItem(id: 'cafe', name: 'Café', emoji: '☕');
  static const igreja = WordItem(id: 'igreja', name: 'Igreja', emoji: '⛪');
  static const palito = WordItem(id: 'palito', name: 'Palito', emoji: '🥢');
  static const saci = WordItem(id: 'saci', name: 'Saci', emoji: '🌪️');
  static const calota = WordItem(id: 'calota', name: 'Calota', emoji: '🛞');
  static const circo = WordItem(id: 'circo', name: 'Circo', emoji: '🎪');
  static const saude = WordItem(id: 'saude', name: 'Saúde', emoji: '💪');
  static const caju = WordItem(id: 'caju', name: 'Caju', emoji: '🌰');
  static const pelado = WordItem(id: 'pelado', name: 'Pelado', emoji: '👶');
  static const mola = WordItem(id: 'mola', name: 'Mola', emoji: '🌀');
  static const apito = WordItem(id: 'apito', name: 'Apito', emoji: '📣');
  static const capa = WordItem(id: 'capa', name: 'Capa', emoji: '🦸');
  static const novelo = WordItem(id: 'novelo', name: 'Novelo', emoji: '🧶');
  static const nove = WordItem(id: 'nove', name: 'Nove', emoji: '9️⃣');
  static const tatu = WordItem(id: 'tatu', name: 'Tatu', emoji: '🦔');
  static const metade = WordItem(id: 'metade', name: 'Metade', emoji: '🌗');
  static const mesa = WordItem(id: 'mesa', name: 'Mesa', emoji: '🍽️');
  static const camisa = WordItem(id: 'camisa', name: 'Camisa', emoji: '👕');
  static const cama = WordItem(id: 'cama', name: 'Cama', emoji: '🛏️');
  static const faca = WordItem(id: 'faca', name: 'Faca', emoji: '🔪');
  static const alfinete = WordItem(id: 'alfinete', name: 'Alfinete', emoji: '📍');
  static const cabide = WordItem(id: 'cabide', name: 'Cabide', emoji: '🧥');
  static const bambu = WordItem(id: 'bambu', name: 'Bambu', emoji: '🎋');
  static const navio = WordItem(id: 'navio', name: 'Navio', emoji: '🚢');
  static const pena = WordItem(id: 'pena', name: 'Pena', emoji: '🪶');
  static const medalha = WordItem(id: 'medalha', name: 'Medalha', emoji: '🏅');
  static const casa = WordItem(id: 'casa', name: 'Casa', emoji: '🏠');
  static const carroca = WordItem(id: 'carroca', name: 'Carroça', emoji: '🛒');
  static const terra = WordItem(id: 'terra', name: 'Terra', emoji: '🌍');
  static const fogo = WordItem(id: 'fogo', name: 'Fogo', emoji: '🔥');
  static const jarra = WordItem(id: 'jarra', name: 'Jarra', emoji: '🏺');
  static const passeio = WordItem(id: 'passeio', name: 'Passeio', emoji: '🚶');
  static const xicara = WordItem(id: 'xicara', name: 'Xícara', emoji: '🫖');
  static const caixa = WordItem(id: 'caixa', name: 'Caixa', emoji: '📦');
  static const cozinha = WordItem(id: 'cozinha', name: 'Cozinha', emoji: '🍳');

  // Letras que os slides não cobrem (H não tem som; K, W e Y vêm de outras
  // línguas): palavras nossas, sem áudio.
  static const hipopotamo = WordItem(
    id: 'hipopotamo',
    name: 'Hipopótamo',
    emoji: '🦛',
  );
  static const hora = WordItem(id: 'hora', name: 'Hora', emoji: '⏰');
  static const kiwi = WordItem(id: 'kiwi', name: 'Kiwi', emoji: '🥝');
  static const karate = WordItem(id: 'karate', name: 'Karatê', emoji: '🥋');
  static const ketchup = WordItem(id: 'ketchup', name: 'Ketchup', emoji: '🍅');
  static const quadro = WordItem(id: 'quadro', name: 'Quadro', emoji: '🖼️');
  static const quatro = WordItem(id: 'quatro', name: 'Quatro', emoji: '4️⃣');
  static const waffle = WordItem(id: 'waffle', name: 'Waffle', emoji: '🧇');
  static const wifi = WordItem(id: 'wifi', name: 'Wi-Fi', emoji: '📶');
  static const web = WordItem(id: 'web', name: 'Web', emoji: '🌐');
  static const yoga = WordItem(id: 'yoga', name: 'Yoga', emoji: '🧘');
  static const yakisoba = WordItem(
    id: 'yakisoba',
    name: 'Yakisoba',
    emoji: '🍜',
  );
  static const yeti = WordItem(id: 'yeti', name: 'Yeti', emoji: '⛄');
}
