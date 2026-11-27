import '../models/mouth_pose.dart';
import '../models/word_item.dart';
import 'word_catalog.dart';

/// Uma fase do Sons das Letras: uma letra, a "boquinha" que faz o som dela
/// ("mmm", "fff"... — o som, não o nome "eme", "efe") e palavras de exemplo
/// que começam com ela.
class LetterPhase {
  /// Letra maiúscula, sem acento ("A", "B"...).
  final String letter;

  /// Boquinha do som. Nos sons que dá pra segurar (vogais, "fff", "mmm",
  /// "sss") é a pose mantida; nos que estouram ("b", "p", "t", "c") é o
  /// fechamento antes do estouro, e [release] é a boca logo depois.
  final MouthPose mouth;

  /// Só nos sons que estouram: a boca depois de soltar o ar.
  final MouthPose? release;

  /// 2 ou 3 palavras de exemplo que têm a letra — no começo, no meio ou no
  /// fim, como nos slides do Método das Boquinhas ("L": Lápis, Pelado,
  /// Mola) — e com o som ensinado ("C" usa "Casa", som de /k/, não "Circo").
  final List<WordItem> words;

  /// Aviso curto mostrado junto da boca (hoje só o "H", que não tem som).
  final String? note;

  const LetterPhase(
    this.letter, {
    required this.mouth,
    this.release,
    required this.words,
    this.note,
  });

  String get title => 'Letra $letter';

  /// Vídeo gravado de uma boca real (som + boca juntos). Opcional: se o
  /// arquivo existir, a tela toca ele no lugar da boquinha animada.
  /// Convenção de nome: a letra minúscula, ex. `assets/videos/letters/b.mp4`.
  String get videoPath => 'assets/videos/letters/${letter.toLowerCase()}.mp4';

  /// Áudio do som da letra, tocado junto com a boquinha animada. Se o
  /// arquivo não existir, a boquinha anima em silêncio.
  String get audioPath => 'assets/audio/letters/${letter.toLowerCase()}.mp3';

  /// Em que ponto da animação (0–1) o som começa: quando a boca chega na
  /// posição nos sons seguráveis; no instante do estouro nos outros.
  double get soundAt => release == null ? _sustainedSoundAt : _burstSoundAt;

  /// Linha do tempo da boquinha: repouso → som → repouso.
  List<MouthKeyframe> get keyframes {
    final release = this.release;
    if (release == null) {
      return [
        const MouthKeyframe(0, MouthPose.rest),
        MouthKeyframe(_sustainedSoundAt, mouth),
        MouthKeyframe(0.72, mouth),
        const MouthKeyframe(1, MouthPose.rest),
      ];
    }
    // Estouro: segura o fechamento tempo suficiente pra criança ver onde a
    // boca/língua encosta, e solta rápido.
    return [
      const MouthKeyframe(0, MouthPose.rest),
      MouthKeyframe(0.12, mouth),
      MouthKeyframe(_burstSoundAt, mouth),
      MouthKeyframe(_burstSoundAt + 0.08, release),
      MouthKeyframe(0.76, release),
      const MouthKeyframe(1, MouthPose.rest),
    ];
  }
}

const _accented = {
  'A': 'ÁÀÂÃ',
  'E': 'ÉÊ',
  'I': 'Í',
  'O': 'ÓÔÕ',
  'U': 'Ú',
};

/// Se [char] (um caractere de uma palavra) é a [letter] da fase, ignorando
/// maiúscula/minúscula e acento ("é" conta como "E"). "ç" não conta como
/// "C": o som é outro.
bool isSameLetter(String char, String letter) {
  final upper = char.toUpperCase();
  return upper == letter || (_accented[letter]?.contains(upper) ?? false);
}

/// Áudio de uma palavra de exemplo, tocado ao tocar nela (opcional).
String wordAudioPath(WordItem word) => 'assets/audio/words/${word.id}.mp3';

const _sustainedSoundAt = 0.1;
const _burstSoundAt = 0.46;

/// Duração da animação da boquinha (uma ida e volta do repouso).
const kMouthAnimationDuration = Duration(milliseconds: 1800);

// ---- Boquinhas ----
// Letras com o mesmo ponto de articulação usam a mesma pose: na boca, "P" e
// "B" (ou "F" e "V", "S" e "Z") são iguais — o que muda é a voz.

// Língua nas vogais (altura e anterioridade): "A" baixa e deitada; "E" e
// "I" com o dorso da frente subindo pro palato duro; "O" e "U" com o fundo
// subindo pro véu. Nas vogais a ponta fica sempre atrás dos dentes de baixo.
const _a = MouthPose(lips: 1, jaw: 1, width: 0.55);
const _e = MouthPose(lips: 0.55, jaw: 0.5, width: 0.8, tongueFront: 0.55);
const _i = MouthPose(lips: 0.3, jaw: 0.05, width: 1, tongueFront: 1);
const _o = MouthPose(lips: 0.7, jaw: 0.7, round: 0.6, tongueBack: 0.45);
const _u = MouthPose(lips: 0.32, jaw: 0.4, round: 1, tongueBack: 0.8);

// Lábios fechados e apertados, depois soltam (P, B).
const _lipsClosed = MouthPose(press: 1);
const _lipsRelease = MouthPose(lips: 0.5, jaw: 0.45);
// Lábios fechados sem apertar, som pelo nariz (M).
const _hum = MouthPose(press: 0.5);
// Dentes de cima no lábio de baixo (F, V).
const _teethOnLip = MouthPose(lips: 0.35, jaw: 0.2, width: 0.65, bite: 1);
// Dentes juntos, sorriso; a ponta da língua perto dos alvéolos sem
// encostar no meio, o ar passa por um sulco (S, Z).
const _hiss = MouthPose(lips: 0.42, jaw: 0, width: 0.9, tongueTip: 0.55, tongueFront: 0.3);
// Dentes juntos, bico; a língua mais pra trás que no "S", com a parte da
// frente do dorso subindo pro começo do palato (X, J, CH).
const _shush = MouthPose(lips: 0.5, jaw: 0.04, round: 0.7, tongueTip: 0.4, tongueFront: 0.7);
// Ponta da língua fina encostada nos alvéolos (atrás dos dentes de cima),
// lados baixos — o ar sai pelos lados. Boca aberta pra ver a língua (L).
const _tongueUpOpen = MouthPose(
  lips: 0.7,
  jaw: 0.6,
  width: 0.6,
  tongueTip: 1,
  tongueNarrow: 1,
);
// Ponta larga vedando nos alvéolos, boca menos aberta, som pelo nariz (N).
const _tongueUp = MouthPose(lips: 0.5, jaw: 0.4, width: 0.65, tongueTip: 1);
// Ponta larga trava o ar nos alvéolos e solta (T, D).
const _tongueStop = MouthPose(lips: 0.4, jaw: 0.12, width: 0.75, tongueTip: 1);
const _tongueRelease = MouthPose(lips: 0.52, jaw: 0.42, width: 0.6);
// Fundo da língua trava o ar no véu palatino e solta (C, G, K, Q); a ponta
// fica embaixo.
const _backStop = MouthPose(lips: 0.58, jaw: 0.5, width: 0.55, tongueBack: 1);
const _backRelease = MouthPose(lips: 0.62, jaw: 0.55, width: 0.55);
// "R" forte de "rato" (no português do Brasil, um chiado no fundo da boca
// ou na garganta): o fundo da língua sobe sem fechar.
const _backFriction = MouthPose(lips: 0.6, jaw: 0.5, width: 0.55, tongueBack: 0.6);

// Sons que só aparecem dentro das palavras (data/lip_sync.dart) — não são
// fase de nenhuma letra.

/// "R" fraco de "pera", "zebra", "porta" (tepe): a ponta da língua bate
/// rápido nos alvéolos.
const kTapPose = MouthPose(lips: 0.5, jaw: 0.4, width: 0.6, tongueTip: 0.85);

/// "LH" de "telhado": o dorso da frente encosta no palato duro, a ponta
/// fica embaixo e o ar sai pelos lados.
const kLhPose = MouthPose(
  lips: 0.55,
  jaw: 0.42,
  width: 0.65,
  tongueFront: 1,
  tongueNarrow: 0.4,
);

/// "NH" de "cozinha": o dorso da frente veda no palato duro, a ponta fica
/// embaixo e o som sai pelo nariz.
const kNhPose = MouthPose(lips: 0.5, jaw: 0.4, width: 0.65, tongueFront: 1);

/// Alfabeto inteiro, de A a Z, uma fase por letra. Sem dificuldade: o
/// usuário achou que não fazia sentido o alfabeto ter níveis, então o menu
/// é uma tela só com as 26 letras (`LetterPickerScreen`) e "Próxima letra"
/// segue a ordem desta lista.
const List<LetterPhase> kLetterPhases = [
  LetterPhase('A', mouth: _a, words: [Words.amor, Words.telhado, Words.porta]),
  LetterPhase(
    'B',
    mouth: _lipsClosed,
    release: _lipsRelease,
    words: [Words.bola, Words.cabide, Words.bambu],
  ),
  LetterPhase(
    'C',
    mouth: _backStop,
    release: _backRelease,
    words: [Words.casa, Words.macaco, Words.cama],
  ),
  LetterPhase(
    'D',
    mouth: _tongueStop,
    release: _tongueRelease,
    words: [Words.dado, Words.medalha, Words.medo],
  ),
  LetterPhase('E', mouth: _e, words: [Words.ema, Words.boneca, Words.cafe]),
  LetterPhase('F', mouth: _teethOnLip, words: [Words.faca, Words.alfinete, Words.cafe]),
  LetterPhase(
    'G',
    mouth: _backStop,
    release: _backRelease,
    words: [Words.gato, Words.foguete, Words.fogo],
  ),
  LetterPhase(
    'H',
    mouth: MouthPose.rest,
    words: [Words.hipopotamo, Words.helicoptero, Words.hora],
    note: 'O H não tem som',
  ),
  LetterPhase('I', mouth: _i, words: [Words.igreja, Words.palito, Words.saci]),
  LetterPhase('J', mouth: _shush, words: [Words.jarra, Words.caju]),
  LetterPhase(
    'K',
    mouth: _backStop,
    release: _backRelease,
    words: [Words.kiwi, Words.karate, Words.ketchup],
  ),
  LetterPhase('L', mouth: _tongueUpOpen, words: [Words.lapis, Words.pelado, Words.mola]),
  LetterPhase('M', mouth: _hum, words: [Words.mesa, Words.camisa, Words.cama]),
  LetterPhase('N', mouth: _tongueUp, words: [Words.navio, Words.caneta, Words.pena]),
  LetterPhase('O', mouth: _o, words: [Words.ovo, Words.calota, Words.circo]),
  LetterPhase(
    'P',
    mouth: _lipsClosed,
    release: _lipsRelease,
    words: [Words.pato, Words.apito, Words.capa],
  ),
  LetterPhase(
    'Q',
    mouth: _backStop,
    release: _backRelease,
    words: [Words.queijo, Words.quadro, Words.quatro],
  ),
  LetterPhase('R', mouth: _backFriction, words: [Words.rato, Words.carroca, Words.terra]),
  LetterPhase('S', mouth: _hiss, words: [Words.sapo, Words.passeio, Words.saci]),
  LetterPhase(
    'T',
    mouth: _tongueStop,
    release: _tongueRelease,
    words: [Words.tatu, Words.metade, Words.moto],
  ),
  LetterPhase('U', mouth: _u, words: [Words.uva, Words.saude, Words.caju]),
  LetterPhase('V', mouth: _teethOnLip, words: [Words.vaca, Words.novelo, Words.nove]),
  LetterPhase('W', mouth: _u, words: [Words.waffle, Words.wifi, Words.web]),
  LetterPhase('X', mouth: _shush, words: [Words.xicara, Words.caixa]),
  LetterPhase('Y', mouth: _i, words: [Words.yoga, Words.yakisoba, Words.yeti]),
  LetterPhase('Z', mouth: _hiss, words: [Words.zebra, Words.cozinha]),
];
