import 'package:flutter/painting.dart';

/// A capivara mascote dos cards da escolha de jogo.
///
/// Estilo escolhido pelo usuário a partir de uma imagem de exemplo: desenho
/// chapado com contorno marrom, capivara de perfil (focinho comprido pra
/// esquerda), olho fechadinho feliz, mexerica na cabeça, e ela sempre dentro
/// de uma cena (atrás de um balcão de madeira, mexendo nos objetos do jogo)
/// em vez de em pé num fundo genérico. As versões anteriores (em pé, 3D
/// suave; depois com olhos grandes de íris e dentes) foram rejeitadas — a
/// segunda o usuário achou assustadora.
///
/// Quadro: x de -84 (ponta do focinho) a 84 (costas), y de -86 (topo da
/// mexerica) a 110 (base do corpo, que fica escondida atrás do balcão).
class CapybaraDrawing {
  /// Boca aberta cantando "Aaa" (Sons das Letras).
  final bool singing;

  const CapybaraDrawing({this.singing = false});

  static const fur = Color(0xFFC98A55);
  static const _furShade = Color(0xFFAE6F3F);
  static const outline = Color(0xFF5B3920);
  static const _earInner = Color(0xFF8E5631);
  static const _ink = Color(0xFF3B2415);
  static const line = 4.0;

  void paint(Canvas c, Offset at, double scale) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(scale);

    // Orelha antes do corpo: o contorno da cabeça cobre a base dela.
    final ear = Rect.fromCenter(
      center: const Offset(36, -58),
      width: 24,
      height: 20,
    );
    c.drawOval(ear, Paint()..color = fur);
    c.drawOval(ear, _stroke(outline, line));
    c.drawOval(
      Rect.fromCenter(center: const Offset(36, -58), width: 11, height: 9),
      Paint()..color = _earInner,
    );

    final body = _silhouette();
    c.drawPath(body, Paint()..color = fur);

    c.save();
    c.clipPath(body);
    // Focinho um tom mais escuro, como na capivara de verdade.
    c.drawOval(
      Rect.fromCenter(center: const Offset(-68, -4), width: 44, height: 60),
      Paint()..color = _furShade,
    );
    // Sombra das costas: dá volume sem sair do desenho chapado.
    c.drawPath(
      Path()
        ..moveTo(60, -40)
        ..cubicTo(78, -10, 84, 60, 92, 120)
        ..lineTo(60, 120)
        ..cubicTo(56, 60, 56, 0, 46, -48)
        ..close(),
      Paint()..color = _furShade.withValues(alpha: 0.6),
    );
    c.restore();

    c.drawPath(body, _stroke(outline, line));

    // Brilho fino no alto da cabeça.
    c.drawPath(
      Path()
        ..moveTo(-30, -50)
        ..quadraticBezierTo(0, -60, 26, -54),
      _stroke(const Color(0x66FFFFFF), 4),
    );

    // Olho fechadinho feliz.
    c.drawArc(
      Rect.fromCircle(center: const Offset(-14, -24), radius: 9),
      3.5,
      2.4,
      false,
      _stroke(_ink, line),
    );

    // Bochecha.
    c.drawOval(
      Rect.fromCenter(center: const Offset(-20, 0), width: 22, height: 12),
      Paint()..color = const Color(0x66FF8A8A),
    );

    // Narina.
    c.save();
    c.translate(-72, -16);
    c.rotate(-0.4);
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 10, height: 6),
      Paint()..color = _ink,
    );
    c.restore();

    if (singing) {
      final mouth = Path()
        ..addOval(
          Rect.fromCenter(center: const Offset(-62, 22), width: 22, height: 24),
        );
      c.drawPath(mouth, Paint()..color = const Color(0xFF7A2C2C));
      c.save();
      c.clipPath(mouth);
      c.drawOval(
        Rect.fromCenter(center: const Offset(-60, 32), width: 18, height: 12),
        Paint()..color = const Color(0xFFFF8C96),
      );
      c.restore();
      c.drawPath(mouth, _stroke(_ink, 3));
    } else {
      c.drawPath(
        Path()
          ..moveTo(-74, 14)
          ..quadraticBezierTo(-64, 24, -52, 16),
        _stroke(_ink, 3.4),
      );
    }

    _tangerine(c, const Offset(-2, -70), 14);
    c.restore();
  }

  /// Patinha apoiada por cima de algo (desenhada depois do objeto).
  static void paintPaw(Canvas c, Offset center, double scale) {
    final r = Rect.fromCenter(
      center: center,
      width: 30 * scale,
      height: 20 * scale,
    );
    c.drawOval(r, Paint()..color = fur);
    c.drawOval(r, _stroke(outline, line * scale));
    final toe = _stroke(outline, 2.6 * scale);
    for (final dx in [-5.0, 5.0]) {
      c.drawLine(
        center + Offset(dx * scale, 3 * scale),
        center + Offset(dx * scale, 9 * scale),
        toe,
      );
    }
  }

  /// Cabeça + corpo numa forma só, de perfil, olhando pra esquerda.
  Path _silhouette() => Path()
    ..moveTo(-48, -44)
    ..cubicTo(-20, -62, 20, -66, 44, -52)
    ..cubicTo(64, -40, 70, -14, 70, 10)
    ..cubicTo(72, 40, 74, 70, 72, 110)
    ..lineTo(-50, 110)
    ..cubicTo(-52, 80, -52, 56, -44, 40)
    ..cubicTo(-58, 38, -76, 28, -80, 6)
    ..cubicTo(-84, -18, -70, -38, -48, -44)
    ..close();

  static void _tangerine(Canvas c, Offset center, double r) {
    final leafPath = Path()
      ..moveTo(center.dx, center.dy - r + 2)
      ..quadraticBezierTo(
        center.dx + r * 0.6,
        center.dy - r * 1.9,
        center.dx + r * 1.3,
        center.dy - r * 1.3,
      )
      ..quadraticBezierTo(
        center.dx + r * 0.7,
        center.dy - r * 0.8,
        center.dx,
        center.dy - r + 2,
      )
      ..close();
    c.drawPath(leafPath, Paint()..color = const Color(0xFF5DBB4C));
    c.drawPath(leafPath, _stroke(outline, 3));

    final rect = Rect.fromCircle(center: center, radius: r);
    c.drawOval(rect, Paint()..color = const Color(0xFFFF9F2E));
    c.drawOval(rect, _stroke(outline, line));
    c.drawArc(
      rect.deflate(r * 0.35),
      3.6,
      0.9,
      false,
      _stroke(const Color(0x99FFFFFF), 3),
    );
  }

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}
