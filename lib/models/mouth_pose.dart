import 'dart:ui' show lerpDouble;

/// Posição da boca num instante — a "boquinha" (articulema) de um som.
/// Todos os campos vão de 0 a 1 pra dar pra interpolar entre duas poses
/// ([lerp]) e animar a passagem de uma pra outra.
class MouthPose {
  /// Abertura entre os lábios (0 = fechados, 1 = bem abertos como no "A").
  final double lips;

  /// Distância entre os dentes de cima e os de baixo (0 = encostados, como
  /// no "S"; 1 = queixo todo aberto). Separado de [lips] porque no "S" os
  /// lábios abrem e os dentes ficam juntos.
  final double jaw;

  /// Largura da boca: 0 = estreita, 0.5 = neutra, 1 = sorriso (como no "I").
  final double width;

  /// Bico: lábios arredondados e projetados pra frente ("O", "U", "X").
  final double round;

  /// Lábios apertados um contra o outro ("B", "P", "M").
  final double press;

  /// Dentes de cima encostados no lábio de baixo ("F", "V").
  final double bite;

  /// Ponta da língua erguida atrás dos dentes de cima ("L", "N", "D", "T").
  final double tongueTip;

  /// Fundo da língua erguido contra o céu da boca, no véu palatino ("C",
  /// "G", "K", "Q", "R" forte; um pouco no "O" e no "U").
  final double tongueBack;

  /// Dorso da frente da língua erguido contra o palato duro, com a ponta
  /// embaixo, atrás dos dentes de baixo ("I", "LH", "NH"; um pouco no "E",
  /// "CH"/"J").
  final double tongueFront;

  /// Ponta da língua fina e pontuda, com os lados baixos pro ar passar
  /// pelos lados ("L"). Sem ela, a ponta erguida é larga e veda o ar
  /// ("T", "D", "N").
  final double tongueNarrow;

  const MouthPose({
    this.lips = 0,
    this.jaw = 0.15,
    this.width = 0.5,
    this.round = 0,
    this.press = 0,
    this.bite = 0,
    this.tongueTip = 0,
    this.tongueBack = 0,
    this.tongueFront = 0,
    this.tongueNarrow = 0,
  });

  /// Boca em repouso: fechada, relaxada.
  static const rest = MouthPose();

  static MouthPose lerp(MouthPose a, MouthPose b, double t) => MouthPose(
    lips: lerpDouble(a.lips, b.lips, t)!,
    jaw: lerpDouble(a.jaw, b.jaw, t)!,
    width: lerpDouble(a.width, b.width, t)!,
    round: lerpDouble(a.round, b.round, t)!,
    press: lerpDouble(a.press, b.press, t)!,
    bite: lerpDouble(a.bite, b.bite, t)!,
    tongueTip: lerpDouble(a.tongueTip, b.tongueTip, t)!,
    tongueBack: lerpDouble(a.tongueBack, b.tongueBack, t)!,
    tongueFront: lerpDouble(a.tongueFront, b.tongueFront, t)!,
    tongueNarrow: lerpDouble(a.tongueNarrow, b.tongueNarrow, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is MouthPose &&
      other.lips == lips &&
      other.jaw == jaw &&
      other.width == width &&
      other.round == round &&
      other.press == press &&
      other.bite == bite &&
      other.tongueTip == tongueTip &&
      other.tongueBack == tongueBack &&
      other.tongueFront == tongueFront &&
      other.tongueNarrow == tongueNarrow;

  @override
  int get hashCode => Object.hash(
    lips,
    jaw,
    width,
    round,
    press,
    bite,
    tongueTip,
    tongueBack,
    tongueFront,
    tongueNarrow,
  );

  /// Esta pose (lábios e queixo) com a língua de [other].
  MouthPose withTongueOf(MouthPose other) => MouthPose(
    lips: lips,
    jaw: jaw,
    width: width,
    round: round,
    press: press,
    bite: bite,
    tongueTip: other.tongueTip,
    tongueBack: other.tongueBack,
    tongueFront: other.tongueFront,
    tongueNarrow: other.tongueNarrow,
  );
}

/// Média de várias poses, campo a campo. Serve pra suavizar uma
/// sequência de poses (média móvel), tirando tremidos quadro a quadro.
MouthPose meanPose(List<MouthPose> poses) {
  double avg(double Function(MouthPose p) field) =>
      poses.fold(0.0, (sum, p) => sum + field(p)) / poses.length;
  return MouthPose(
    lips: avg((p) => p.lips),
    jaw: avg((p) => p.jaw),
    width: avg((p) => p.width),
    round: avg((p) => p.round),
    press: avg((p) => p.press),
    bite: avg((p) => p.bite),
    tongueTip: avg((p) => p.tongueTip),
    tongueBack: avg((p) => p.tongueBack),
    tongueFront: avg((p) => p.tongueFront),
    tongueNarrow: avg((p) => p.tongueNarrow),
  );
}

/// A boca quadro a quadro durante um som: uma pose a cada [stepMs] ms,
/// calculada a partir do volume do áudio (ver data/lip_sync.dart). O áudio
/// começa a tocar em [soundStart]; antes disso a boca já vai se preparando,
/// como numa boca de verdade.
class MouthTrack {
  static const stepMs = 10;

  final List<MouthPose> frames;
  final Duration soundStart;

  const MouthTrack(this.frames, {required this.soundStart});

  Duration get duration => Duration(milliseconds: frames.length * stepMs);

  /// Pose no instante [t] da trilha, interpolando entre os dois quadros
  /// vizinhos (a tela desenha a 60+ fps, mais rápido que um quadro a cada
  /// 10 ms).
  MouthPose poseAt(Duration t) {
    final x = t.inMicroseconds / 1000 / stepMs;
    if (x <= 0) return frames.first;
    if (x >= frames.length - 1) return frames.last;
    final i = x.floor();
    return MouthPose.lerp(frames[i], frames[i + 1], x - i);
  }
}

/// Um ponto da animação: em [at] (fração 0–1 da duração) a boca está em
/// [pose].
class MouthKeyframe {
  final double at;
  final MouthPose pose;

  const MouthKeyframe(this.at, this.pose);
}

/// Pose em [t] (0–1) numa lista de keyframes ordenada por `at`.
MouthPose mouthPoseAt(List<MouthKeyframe> keyframes, double t) {
  if (t <= keyframes.first.at) return keyframes.first.pose;
  for (var i = 1; i < keyframes.length; i++) {
    final next = keyframes[i];
    if (t <= next.at) {
      final previous = keyframes[i - 1];
      final local = (t - previous.at) / (next.at - previous.at);
      // Suaviza a chegada e a saída de cada pose (smoothstep): boca de
      // verdade não muda de posição em velocidade constante.
      final eased = local * local * (3 - 2 * local);
      return MouthPose.lerp(previous.pose, next.pose, eased);
    }
  }
  return keyframes.last.pose;
}
