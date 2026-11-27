import 'dart:math' as math;

import '../models/mouth_pose.dart';
import '../models/word_item.dart';
import 'audio_envelopes.dart';
import 'letter_phases.dart';

/// Monta a trilha da boquinha (uma pose a cada 10 ms) a partir do volume do
/// áudio, pra boca abrir e fechar junto com o som de verdade — não num
/// tempo fixo que ignora quanto cada áudio dura.
///
/// - Letra: a boca vai pra pose do som antes dele começar, segura enquanto
///   o som dura e volta ao repouso quando ele acaba. Nos sons que estouram
///   ("p", "b", "t", "c"...) fica fechada até o estouro — inclusive durante
///   o "mmm" que vem antes do "b"/"d"/"g" — e abre no instante dele.
/// - Palavra: cada letra vira uma pose (com as regras de leitura do
///   português: "qu", "ch", "lh", "ç", "e"/"o" finais...), e as vogais são
///   alinhadas com os picos de volume, que são as sílabas.

/// Quanto a boca se adianta ao som. Boca de verdade se mexe antes: o som
/// só sai depois que lábios/língua chegam na posição.
const _letterPreRollMs = 200;
const _burstPreRollMs = 320;
const _wordPreRollMs = 160;
const _tailMs = 220;
const _step = kEnvelopeStepMs;

MouthTrack letterTrack(LetterPhase phase) {
  final envelope = kAudioEnvelopes[phase.audioPath];
  if (envelope == null) return _keyframeTrack(phase);
  final level = _Level(envelope);
  final burst = phase.release != null;
  final pre = (burst ? _burstPreRollMs : _letterPreRollMs) ~/ _step;
  final total = pre + envelope.length + _tailMs ~/ _step;
  // Estouro: o primeiro quadro bem alto. Som segurado: dura até o último
  // quadro com som.
  final onset = burst ? level.firstAbove(0.5) : 0;
  final soundEnd = level.lastAbove(0.2);
  final release = phase.release ?? phase.mouth;

  final frames = <MouthPose>[
    for (var k = 0; k < total; k++)
      if (k < pre)
        MouthPose.lerp(MouthPose.rest, phase.mouth, _smoothstep(0, pre * 0.8, k.toDouble()))
      else if (!burst)
        // Segura a pose firme enquanto o som dura (a criança precisa ver a
        // posição), e fecha acompanhando o fim do som.
        MouthPose.lerp(
          MouthPose.rest,
          phase.mouth,
          k - pre <= soundEnd ? math.max(0.9, level.open(k - pre)) : level.open(k - pre),
        )
      else if (k - pre < onset)
        phase.mouth
      else
        MouthPose.lerp(
          phase.mouth,
          MouthPose.lerp(MouthPose.rest, release, level.open(k - pre)),
          _smoothstep(onset.toDouble(), onset + 5.0, (k - pre).toDouble()),
        ),
  ];
  return MouthTrack(_smoothed(frames, 1), soundStart: Duration(milliseconds: pre * _step));
}

/// Letra sem áudio (o H): a animação de sempre, num tempo fixo.
MouthTrack _keyframeTrack(LetterPhase phase) {
  final count = kMouthAnimationDuration.inMilliseconds ~/ _step;
  return MouthTrack(
    [for (var k = 0; k <= count; k++) mouthPoseAt(phase.keyframes, k / count)],
    soundStart: kMouthAnimationDuration * phase.soundAt,
  );
}

/// Trilha de uma palavra, ou null se ela não tiver áudio.
MouthTrack? wordTrack(WordItem word) {
  final envelope = kAudioEnvelopes[wordAudioPath(word)];
  if (envelope == null) return null;
  final level = _Level(envelope);
  final visemes = _visemes(word.name);
  final pre = _wordPreRollMs ~/ _step;
  final total = pre + envelope.length + _tailMs ~/ _step;

  // Onde a palavra é falada de fato (fora disso é respiração/ruído).
  final start = level.firstAbove(0.15);
  final end = math.max(start + 1, level.lastAbove(0.15));

  // Cada letra ganha um pedaço do tempo: vogal dura mais que consoante, e
  // consoante que estoura é a mais curta.
  final weights = [for (final v in visemes) v.weight];
  final sum = weights.fold(0.0, (a, b) => a + b);
  final bounds = <double>[0];
  for (final w in weights) {
    bounds.add(bounds.last + w / sum);
  }

  final warp = _syllableWarp(visemes, bounds, level, start, end);
  final keyframes = <MouthKeyframe>[];
  for (var j = 0; j < visemes.length; j++) {
    final a = bounds[j];
    final b = bounds[j + 1];
    for (final f in const [0.25, 0.75]) {
      final frame = warp(a + (b - a) * f);
      keyframes.add(MouthKeyframe(frame / envelope.length, visemes[j].pose));
    }
  }
  if (keyframes.isEmpty) return null;

  final frames = <MouthPose>[
    for (var k = 0; k < total; k++)
      MouthPose.lerp(
        MouthPose.rest,
        mouthPoseAt(keyframes, (k - pre) / envelope.length),
        level.open(k - pre),
      ),
  ];
  return MouthTrack(_smoothed(frames, 2), soundStart: Duration(milliseconds: pre * _step));
}

/// Transforma a posição "proporcional" (0–1) de cada letra na palavra em
/// quadro do áudio. Se o nº de picos de volume bater com o nº de sílabas
/// (grupos de vogais), cada vogal cai em cima do seu pico; senão, espalha
/// as letras por igual entre o começo e o fim da fala.
double Function(double) _syllableWarp(
  List<_Viseme> visemes,
  List<double> bounds,
  _Level level,
  int start,
  int end,
) {
  final nuclei = <double>[];
  for (var j = 0; j < visemes.length; j++) {
    if (!visemes[j].vowel) continue;
    var last = j;
    while (last + 1 < visemes.length && visemes[last + 1].vowel) {
      last++;
    }
    nuclei.add((bounds[j] + bounds[last + 1]) / 2);
    j = last;
  }
  final peaks = level.peaks(start, end);
  final anchors = <(double, double)>[(0, start.toDouble())];
  if (peaks.length == nuclei.length) {
    for (var k = 0; k < peaks.length; k++) {
      anchors.add((nuclei[k], peaks[k].toDouble()));
    }
  }
  anchors.add((1, end.toDouble()));

  return (u) {
    for (var k = 1; k < anchors.length; k++) {
      final (u1, f1) = anchors[k];
      if (u <= u1 || k == anchors.length - 1) {
        final (u0, f0) = anchors[k - 1];
        return u1 == u0 ? f1 : f0 + (f1 - f0) * (u - u0) / (u1 - u0);
      }
    }
    return end.toDouble();
  };
}

/// Média móvel de ±[radius] quadros: deixa o movimento contínuo.
List<MouthPose> _smoothed(List<MouthPose> frames, int radius) => [
  for (var i = 0; i < frames.length; i++)
    meanPose(
      frames.sublist(
        math.max(0, i - radius),
        math.min(frames.length, i + radius + 1),
      ),
    ),
];

double _smoothstep(double edge0, double edge1, double x) {
  if (edge1 <= edge0) return x < edge0 ? 0 : 1;
  final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Volume de um áudio normalizado pra 0–1, já descontado o ruído de fundo
/// da gravação.
class _Level {
  final List<double> values;

  _Level._(this.values);

  factory _Level(List<int> envelope) {
    final sorted = [...envelope]..sort();
    // Ruído de fundo: o nível dos 10% mais baixos — mas um som que não
    // para nunca (um "fff" do começo ao fim) não tem trecho de silêncio,
    // por isso o teto.
    final noise = math.min(sorted[sorted.length ~/ 10], 35) + 3;
    final peak = sorted.last;
    final range = math.max(1, peak - noise);
    return _Level._([
      for (final v in envelope) ((v - noise) / range).clamp(0.0, 1.0),
    ]);
  }

  double at(int i) => i < 0 || i >= values.length ? 0 : values[i];

  /// Quanto a boca está aberta no quadro [i] (0–1). Olha 60 ms pra frente:
  /// a boca chega antes do som.
  double open(int i) {
    var m = 0.0;
    for (var j = i; j <= i + 6; j++) {
      m = math.max(m, at(j));
    }
    return _smoothstep(0.12, 0.55, m);
  }

  int firstAbove(double v) {
    final i = values.indexWhere((x) => x > v);
    return i < 0 ? 0 : i;
  }

  int lastAbove(double v) {
    final i = values.lastIndexWhere((x) => x > v);
    return i < 0 ? values.length - 1 : i;
  }

  /// Picos de volume (as sílabas) entre [from] e [to].
  List<int> peaks(int from, int to) {
    double smooth(int i) {
      var sum = 0.0;
      for (var j = i - 3; j <= i + 3; j++) {
        sum += at(j);
      }
      return sum / 7;
    }

    final s = [for (var i = 0; i < values.length; i++) smooth(i)];
    final result = <int>[];
    for (var i = math.max(1, from); i < math.min(to, s.length - 1); i++) {
      if (s[i] < 0.3 || s[i] < s[i - 1] || s[i] <= s[i + 1]) continue;
      if (result.isEmpty) {
        result.add(i);
        continue;
      }
      final last = result.last;
      final valley = s.sublist(last, i + 1).reduce(math.min);
      final distinct = math.min(s[last], s[i]) - valley >= 0.1 && i - last >= 8;
      if (distinct) {
        result.add(i);
      } else if (s[i] > s[last]) {
        result[result.length - 1] = i;
      }
    }
    return result;
  }
}

class _Viseme {
  final MouthPose pose;
  final bool vowel;
  final double weight;

  /// Som feito só com os lábios ("p", "b", "m", "f", "v"): a língua fica
  /// livre e já vai pra posição da vogal seguinte.
  final bool labial;

  const _Viseme(this.pose, {this.vowel = false, this.weight = 1, this.labial = false});
}

/// Poses de uma palavra, uma por som (não por letra: "qu", "ch", "ss"...
/// são um som só, e o "h" sozinho não tem som). Pública pros testes.
List<MouthPose> wordPoses(String word) => [for (final v in _visemes(word)) v.pose];

const _plain = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a',
  'é': 'e', 'ê': 'e',
  'í': 'i',
  'ó': 'o', 'ô': 'o', 'õ': 'o',
  'ú': 'u', 'ü': 'u',
};

List<_Viseme> _visemes(String word) {
  final s = [
    for (final c in word.toLowerCase().split(''))
      if (RegExp('[a-zçáàâãéêíóôõúü]').hasMatch(c)) _plain[c] ?? c,
  ];
  bool isVowel(int i) => i < s.length && 'aeiouy'.contains(s[i]);
  String at(int i) => i < s.length ? s[i] : '';
  final soft = {'e', 'i'};

  final out = <_Viseme>[];
  void vowel(String v) => out.add(_Viseme(_pose(v), vowel: true, weight: 1.6));
  void consonant(String letter) {
    final phase = _phase(letter);
    final stop = phase.release != null;
    out.add(_Viseme(phase.mouth, weight: stop ? 0.7 : 1, labial: 'BPMFV'.contains(letter)));
  }

  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    final last = i == s.length - 1;
    switch (c) {
      case 'a' || 'i' || 'u':
        vowel(c.toUpperCase());
      // "e"/"o" no fim da palavra soam "i"/"u" ("nove", "fogo").
      case 'e':
        vowel(last ? 'I' : 'E');
      case 'o':
        vowel(last ? 'U' : 'O');
      case 'y':
        vowel('I');
      case 'w':
        vowel('U');
      case 'h':
        break; // sem som sozinho; "ch"/"lh"/"nh" são tratados antes
      case 'c':
        if (at(i + 1) == 'h') {
          consonant('X');
          i++;
        } else {
          consonant(soft.contains(at(i + 1)) ? 'S' : 'C');
        }
      case 'ç' || 'z':
        consonant('S');
      case 'g':
        if (soft.contains(at(i + 1))) {
          consonant('J');
        } else {
          consonant('G');
          // "gue"/"gui": o "u" não soa.
          if (at(i + 1) == 'u' && soft.contains(at(i + 2))) i++;
        }
      case 'q':
        consonant('Q');
        if (at(i + 1) == 'u' && soft.contains(at(i + 2))) i++;
      case 'l':
        if (at(i + 1) == 'h') {
          out.add(const _Viseme(kLhPose));
          i++;
        } else if (!isVowel(i + 1)) {
          vowel('U'); // "l" no fim da sílaba soa "u" ("alfinete")
        } else {
          consonant('L');
        }
      case 'n':
        if (at(i + 1) == 'h') {
          out.add(const _Viseme(kNhPose));
          i++;
        } else if (isVowel(i + 1)) {
          consonant('N');
        } // senão só deixa a vogal anterior nasal
      case 'm':
        // "m" antes de consoante (fora "b"/"p") ou no fim: só nasaliza.
        if (isVowel(i + 1) || at(i + 1) == 'b' || at(i + 1) == 'p') {
          consonant('M');
        }
      case 'r':
        // "R" forte (fundo da língua) no começo da palavra, no "rr" e
        // depois de "n"/"l"/"s" ("honra"); nos outros casos ("pera",
        // "zebra", "porta") é o fraco, a ponta da língua batendo.
        if (i == 0 || at(i + 1) == 'r' || 'nls'.contains(at(i - 1))) {
          consonant('R');
          if (at(i + 1) == 'r') i++;
        } else {
          out.add(const _Viseme(kTapPose, weight: 0.6));
        }
      case 's':
        consonant('S');
        if (at(i + 1) == 's') i++; // "ss"
      case 'k':
        consonant('K');
      default:
        consonant(c.toUpperCase());
    }
  }
  // Coarticulação: nos sons de lábio a língua não tem o que fazer e já se
  // prepara pra vogal seguinte (no fim da palavra, fica na anterior) — em
  // "pipa" ela fica no "i" o tempo todo, em vez de cair no "p".
  for (var j = 0; j < out.length; j++) {
    if (!out[j].labial) continue;
    final next = out.indexWhere((v) => v.vowel, j + 1);
    final previous = out.lastIndexWhere((v) => v.vowel, j);
    final source = next >= 0 ? next : previous;
    if (source < 0) continue;
    final v = out[j];
    out[j] = _Viseme(v.pose.withTongueOf(out[source].pose), weight: v.weight, labial: true);
  }
  return out;
}

MouthPose _pose(String letter) => _phase(letter).mouth;

final _phasesByLetter = {
  for (final phase in kLetterPhases) phase.letter: phase,
};

LetterPhase _phase(String letter) => _phasesByLetter[letter]!;
