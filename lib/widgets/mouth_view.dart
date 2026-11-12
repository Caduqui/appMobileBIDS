import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/mouth_pose.dart';

/// Desenha a "boquinha": uma boca vista de frente (lábios, dentes e língua)
/// na [pose] dada. Não anima sozinha — quem anima é a tela, trocando a pose
/// a cada quadro.
class MouthView extends StatelessWidget {
  final MouthPose pose;

  const MouthView({super.key, required this.pose});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MouthPainter(pose), size: Size.infinite);
  }
}

/// Tudo é desenhado num sistema de coordenadas próprio: (0,0) é o meio da
/// boca e o menor lado do widget vai de -1 a 1. Assim as medidas abaixo
/// (frações do rosto) valem pra qualquer tamanho de tela.
class _MouthPainter extends CustomPainter {
  final MouthPose pose;

  _MouthPainter(this.pose);

  static const _skinLight = Color(0xFFF7D2B6);
  static const _skinDark = Color(0xFFE2AA88);
  static const _skinShadow = Color(0xFF9C5B3F);
  static const _lipLight = Color(0xFFD9737A);
  static const _lipDark = Color(0xFFB4444F);
  static const _lipLine = Color(0xFF74262F);
  static const _cavity = Color(0xFF3A0D12);
  static const _tongueLight = Color(0xFFEE8C96);
  static const _tongueDark = Color(0xFFB8525E);
  static const _tooth = Color(0xFFFBF8F1);
  static const _toothBacking = Color(0xFFCFC6BA);

  /// Borda de baixo dos dentes de cima. Fixa: quem se mexe é o queixo.
  static const _upperTeethEdge = 0.045;

  @override
  void paint(Canvas canvas, Size size) {
    // Zoom: o quadro é um close da boca, ela ocupa quase toda a largura.
    final unit = size.shortestSide / 2 * 1.35;
    final halfW = size.width / 2 / unit;
    final halfH = size.height / 2 / unit;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(unit);

    final p = pose;

    // ---- Medidas da boca nesta pose ----
    final halfWidth = 0.62 * (0.88 + 0.24 * p.width) * (1 - 0.42 * p.round);
    final cornerX = halfWidth + 0.03;
    // No "F"/"V" o lábio de cima sobe um pouco pra mostrar os dentes e o
    // de baixo sobe até encostar neles.
    final upperOpen = 0.09 * p.lips + 0.03 * p.round * p.lips + 0.05 * p.bite;
    final lowerOpen = 0.46 * p.lips * (1 - p.bite) + 0.02 * p.bite;
    // Lábio estica (sorriso) → afina; faz bico → engrossa; aperta → afina.
    final thickness =
        (1 + 0.35 * p.round) * (1 - 0.35 * p.press) * (1 - 0.2 * (p.width - 0.5));
    final upperLip = 0.12 * thickness;
    final lowerLip = 0.17 * thickness;
    // Quanto mais bico, mais redonda a abertura.
    final bulge = 0.45 + 0.35 * p.round;
    final lowerTeethEdge = _upperTeethEdge + 0.005 + 0.40 * p.jaw;

    final inner = Path()
      ..moveTo(-halfWidth, 0)
      ..cubicTo(
        -halfWidth * bulge, -upperOpen / 0.75,
        halfWidth * bulge, -upperOpen / 0.75,
        halfWidth, 0,
      )
      ..cubicTo(
        halfWidth * bulge, lowerOpen / 0.75,
        -halfWidth * bulge, lowerOpen / 0.75,
        -halfWidth, 0,
      )
      ..close();

    final top = -(upperOpen + upperLip);
    final peakX = 0.2 * halfWidth;
    final shoulderY = -upperOpen * 0.6 - upperLip * 0.9;
    final outer = Path()
      ..moveTo(-cornerX, 0)
      ..cubicTo(-halfWidth * 0.6, shoulderY, -peakX * 1.8, top, -peakX, top)
      // Arco do cupido: o "v" no meio do lábio de cima.
      ..quadraticBezierTo(0, top + upperLip * 0.3, peakX, top)
      ..cubicTo(peakX * 1.8, top, halfWidth * 0.6, shoulderY, cornerX, 0)
      ..cubicTo(
        halfWidth * 0.55, (lowerOpen + lowerLip) / 0.75,
        -halfWidth * 0.55, (lowerOpen + lowerLip) / 0.75,
        -cornerX, 0,
      )
      ..close();

    _paintSkin(canvas, halfW, halfH, top, lowerOpen + lowerLip, halfWidth);

    // ---- Dentro da boca (só aparece pela abertura dos lábios) ----
    canvas.save();
    canvas.clipPath(inner);
    canvas.drawRect(
      Rect.fromLTRB(-1, -1, 1, 1),
      Paint()..color = _cavity,
    );
    _paintTongue(canvas, p, lowerTeethEdge);
    _paintTeethRow(canvas, top: lowerTeethEdge, bottom: lowerTeethEdge + 0.4, upper: false);
    _paintTeethRow(canvas, top: -0.4, bottom: _upperTeethEdge, upper: true);
    // Risco entre as duas fileiras: sem ele, com os dentes encostados
    // ("S", "X") elas viram um bloco branco só.
    canvas.drawLine(
      const Offset(-0.6, _upperTeethEdge + 0.004),
      const Offset(0.6, _upperTeethEdge + 0.004),
      Paint()
        ..color = _cavity.withValues(alpha: 0.55)
        ..strokeWidth = 0.01,
    );
    // Sombra que o lábio de cima faz sobre os dentes.
    canvas.drawRect(
      Rect.fromLTRB(-1, -upperOpen - 0.02, 1, -upperOpen + 0.09),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, -upperOpen - 0.02),
          Offset(0, -upperOpen + 0.09),
          [Colors.black.withValues(alpha: 0.35), Colors.transparent],
        ),
    );
    canvas.restore();

    // ---- Lábios ----
    final lips = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(
      lips,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, lowerOpen + lowerLip),
          [_lipDark, _lipLight, _lipDark],
          [0, 0.62, 1],
        ),
    );
    // Brilho do lábio de baixo.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, lowerOpen + lowerLip * 0.5),
        width: halfWidth * 0.9,
        height: lowerLip * 0.32,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.025),
    );
    // Risco entre os lábios fechados — some conforme a boca abre.
    final seam = (1 - p.lips * 8).clamp(0.0, 1.0);
    if (seam > 0) {
      canvas.drawPath(
        Path()
          ..moveTo(-cornerX, 0)
          ..quadraticBezierTo(0, 0.03 * (1 - p.press), cornerX, 0),
        Paint()
          ..color = _lipLine.withValues(alpha: seam)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.014,
      );
    }

    // ---- "F"/"V": dentes de cima por cima do lábio de baixo ----
    if (p.bite > 0.05) {
      canvas.save();
      // Recorte em forma de abertura de boca: em cima acompanha a borda do
      // lábio de cima (os dentes saem de trás dele), embaixo desce um pouco
      // sobre o lábio de baixo e afina até os cantos.
      final teethBottom = _upperTeethEdge + 0.035 * p.bite;
      canvas.clipPath(
        Path()
          ..moveTo(-halfWidth, 0)
          ..cubicTo(
            -halfWidth * bulge, -upperOpen / 0.75,
            halfWidth * bulge, -upperOpen / 0.75,
            halfWidth, 0,
          )
          ..cubicTo(
            halfWidth * bulge, teethBottom / 0.75,
            -halfWidth * bulge, teethBottom / 0.75,
            -halfWidth, 0,
          )
          ..close(),
      );
      _paintTeethRow(canvas, top: -0.4, bottom: teethBottom + 0.05, upper: true);
      canvas.restore();
    }

    canvas.restore();
  }

  void _paintSkin(
    Canvas canvas,
    double halfW,
    double halfH,
    double lipTop,
    double lipBottom,
    double halfWidth,
  ) {
    final face = Rect.fromLTRB(-halfW, -halfH, halfW, halfH);
    canvas.drawRect(
      face,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(0, -0.1),
          1.5,
          [_skinLight, _skinDark],
        ),
    );
    final shadow = Paint()
      ..color = _skinShadow.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.05);
    // Sulco entre o nariz e o lábio.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-0.06, -0.72, 0.06, lipTop - 0.02),
        const Radius.circular(0.06),
      ),
      Paint()
        ..color = _skinShadow.withValues(alpha: 0.13)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.04),
    );
    // Sombra debaixo do lábio de baixo (desce junto com o queixo).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, lipBottom + 0.08),
        width: halfWidth * 1.3,
        height: 0.1,
      ),
      shadow,
    );
  }

  void _paintTongue(Canvas canvas, MouthPose p, double lowerTeethEdge) {
    // Repouso: deitada atrás dos dentes de baixo, só o dorso aparece.
    final restTop = lowerTeethEdge - 0.05;
    // Ponta erguida: encosta atrás dos dentes de cima, tapando o vão.
    final tipTop = _upperTeethEdge - 0.04;
    // Fundo erguido: um morro largo que fecha a garganta.
    final backTop = _upperTeethEdge + 0.03;
    final tongueTop =
        restTop + (tipTop - restTop) * p.tongueTip + (backTop - restTop) * p.tongueBack;
    final halfTongue = 0.40 - 0.12 * p.tongueTip + 0.14 * p.tongueBack;

    final tongue = Path()
      ..moveTo(-halfTongue, 1)
      ..cubicTo(-halfTongue, tongueTop + 0.06, -halfTongue * 0.55, tongueTop, 0, tongueTop)
      ..cubicTo(halfTongue * 0.55, tongueTop, halfTongue, tongueTop + 0.06, halfTongue, 1)
      ..close();
    // O fundo da língua fica mais longe da luz: escurece.
    final light = Color.lerp(_tongueLight, _tongueDark, 0.45 * p.tongueBack)!;
    canvas.drawPath(
      tongue,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, tongueTop),
          Offset(0, tongueTop + 0.45),
          [light, _tongueDark],
        ),
    );
    // Risco do meio da língua. Com a ponta erguida vemos o lado de baixo
    // dela, onde esse risco (o freio) é bem marcado.
    canvas.drawLine(
      Offset(0, tongueTop + 0.04),
      Offset(0, tongueTop + 0.4),
      Paint()
        ..color = _tongueDark.withValues(alpha: 0.45 + 0.4 * p.tongueTip)
        ..strokeWidth = 0.012 + 0.012 * p.tongueTip
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Uma fileira de dentes centralizada. [count] = dentes de cada lado do
  /// meio. Os de cima têm os dois da frente maiores; os de baixo são todos
  /// pequenos.
  void _paintTeethRow(
    Canvas canvas, {
    required double top,
    required double bottom,
    required bool upper,
    int count = 5,
  }) {
    final widths = upper
        ? const [0.135, 0.105, 0.105, 0.095, 0.095]
        : const [0.085, 0.085, 0.095, 0.095, 0.095];
    const gap = 0.007;

    var total = 0.0;
    for (var i = 0; i < count; i++) {
      total += widths[i] + gap;
    }
    // Fundo acinzentado: sem ele o vão entre dois dentes mostraria o fundo
    // escuro da boca, como se faltasse dente.
    canvas.drawRect(
      Rect.fromLTRB(-total, top, total, bottom),
      Paint()..color = _toothBacking,
    );

    for (final side in const [-1.0, 1.0]) {
      var x = gap / 2;
      for (var i = 0; i < count; i++) {
        // A fileira faz uma curva: os dentes do lado ficam mais curtos e
        // mais escuros (estão mais pro fundo da boca).
        final arc = 0.006 * i * i;
        final rect = upper
            ? Rect.fromLTRB(x, top, x + widths[i], bottom - arc)
            : Rect.fromLTRB(x, top + arc, x + widths[i], bottom);
        final shade = Color.lerp(_tooth, _toothBacking, i * 0.16)!;
        canvas.save();
        canvas.scale(side, 1);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(0.022)),
          Paint()..color = shade,
        );
        canvas.restore();
        x += widths[i] + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_MouthPainter oldDelegate) => oldDelegate.pose != pose;
}
