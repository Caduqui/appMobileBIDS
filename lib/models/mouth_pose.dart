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

  /// Fundo da língua erguido contra o céu da boca ("C", "G", "K", "Q", "R").
  final double tongueBack;

  const MouthPose({
    this.lips = 0,
    this.jaw = 0.15,
    this.width = 0.5,
    this.round = 0,
    this.press = 0,
    this.bite = 0,
    this.tongueTip = 0,
    this.tongueBack = 0,
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
  );
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
