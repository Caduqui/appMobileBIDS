import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'capybara_drawing.dart';

/// Qual cena desenhar no card da tela de escolha de jogo.
enum MinigameArtKind { memory, completion, letterSounds }

/// Arte dos cards da tela de escolha de jogo: a capivara mascote atrás de um
/// balcão de madeira, mexendo nos objetos de cada minigame, em desenho
/// chapado com contorno marrom (ver [CapybaraDrawing]).
///
/// É desenhada em código, não um arquivo de imagem, por escolha do usuário:
/// fica nítida em qualquer tela e dá pra ajustar cor/pose aqui mesmo. Sempre
/// na proporção [aspectRatio] (retrato 3:4) — o card usa a mesma, então nada
/// é cortado.
class MinigameArt extends StatelessWidget {
  final MinigameArtKind kind;

  const MinigameArt(this.kind, {super.key});

  static const double aspectRatio = 3 / 4;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      // As letras da arte usam a mesma fonte do resto do app (a do tema).
      child: CustomPaint(
        painter: _ArtPainter(
          kind,
          DefaultTextStyle.of(context).style.fontFamily,
        ),
      ),
    );
  }
}

// Todas as cenas são desenhadas num quadro de referência de 300x400 e
// escaladas pro tamanho real — assim as coordenadas abaixo não dependem do
// tamanho do card (celular x tablet).
const _refWidth = 300.0;
const _refHeight = 400.0;

const _outline = CapybaraDrawing.outline;
const _line = CapybaraDrawing.line;

// Uma cor por jogo, na borda do card e nos detalhes: o mascote é o mesmo, a
// cor é o que diferencia os cards de longe (criança ainda não lê o título).
const _accent = {
  MinigameArtKind.memory: Color(0xFF4FA8F0),
  MinigameArtKind.completion: Color(0xFF4DBA5A),
  MinigameArtKind.letterSounds: Color(0xFF9B6BEA),
};

class _ArtPainter extends CustomPainter {
  final MinigameArtKind kind;
  final String? fontFamily;

  _ArtPainter(this.kind, this.fontFamily);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _refWidth, size.height / _refHeight);
    final accent = _accent[kind]!;
    const full = Rect.fromLTWH(0, 0, _refWidth, _refHeight);
    // Fundo chapado clarinho na cor do jogo (escolha do usuário).
    canvas.drawRect(
      full,
      Paint()..color = Color.lerp(accent, Colors.white, 0.8)!,
    );
    switch (kind) {
      case MinigameArtKind.memory:
        _memoryScene(canvas);
      case MinigameArtKind.completion:
        _completionScene(canvas, accent);
      case MinigameArtKind.letterSounds:
        _letterSoundsScene(canvas, accent);
    }
    // Borda grossa na cor do jogo.
    canvas.drawRRect(
      RRect.fromRectAndRadius(full.deflate(4), const Radius.circular(26)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = accent,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArtPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.fontFamily != fontFamily;

  // ---- Cenas ----

  void _memoryScene(Canvas c) {
    _sparkle(c, const Offset(46, 150), 10);
    _sparkle(c, const Offset(262, 120), 8);
    _sparkle(c, const Offset(70, 70), 7);
    const CapybaraDrawing().paint(c, const Offset(188, 206), 1.12);
    _counter(c);
    _memoryCard(c, const Offset(62, 248), -0.1, faceUp: false);
    _memoryCard(c, const Offset(240, 250), 0.1, faceUp: true);
    // Patinhas apoiadas no balcão.
    CapybaraDrawing.paintPaw(c, const Offset(138, 292), 1.1);
    CapybaraDrawing.paintPaw(c, const Offset(178, 293), 1.1);
  }

  void _completionScene(Canvas c, Color accent) {
    _sparkle(c, const Offset(50, 110), 9);
    _sparkle(c, const Offset(264, 96), 7);
    const CapybaraDrawing().paint(c, const Offset(196, 186), 1.1);
    _counter(c);
    // A palavra com a lacuna (G _ T O) no balcão; a capivara traz na boca a
    // letra que falta.
    const y = 262.0;
    _block(c, const Offset(46, y), 52, const Color(0xFF4A90F0), 'G');
    _slot(c, const Offset(108, y), 52);
    _block(c, const Offset(170, y), 52, const Color(0xFFFF6464), 'T');
    _block(c, const Offset(232, y), 52, const Color(0xFF9B6BEA), 'O');
    _block(
      c,
      const Offset(114, 214),
      46,
      const Color(0xFFFFC23C),
      'A',
      angle: -0.12,
    );
  }

  void _letterSoundsScene(Canvas c, Color accent) {
    const CapybaraDrawing(singing: true).paint(c, const Offset(196, 210), 1.12);
    _counter(c);
    // Ondinhas de som saindo da boca, e o balão com a letra apontando pra
    // ela. (Bolinhas em fila pareciam balão de pensamento.)
    for (final r in [22.0, 36.0]) {
      c.drawArc(
        Rect.fromCircle(center: const Offset(120, 242), radius: r),
        2.0,
        1.3,
        false,
        _stroke(accent, 5),
      );
    }
    CapybaraDrawing.paintPaw(c, const Offset(150, 292), 1.1);
    CapybaraDrawing.paintPaw(c, const Offset(190, 293), 1.1);
    _speechBubble(c, const Rect.fromLTWH(18, 36, 128, 104), 'A', accent);
  }

  // ---- Cenário ----

  /// Balcão de madeira na frente da capivara (esconde a base do corpo).
  void _counter(Canvas c) {
    const front = Rect.fromLTRB(22, 304, 278, 410);
    c.drawRect(front, Paint()..color = const Color(0xFFD08E52));
    final plank = _stroke(_outline, 3);
    for (var x = front.left + 43; x < front.right - 10; x += 43) {
      c.drawLine(Offset(x, front.top), Offset(x, front.bottom), plank);
    }
    c.drawRect(front, _stroke(_outline, _line));
    final rim = RRect.fromLTRBR(10, 288, 290, 310, const Radius.circular(11));
    _outlined(c, Path()..addRRect(rim), const Color(0xFFE6B072));
    c.drawLine(
      const Offset(26, 295),
      const Offset(150, 295),
      _stroke(const Color(0x80FFFFFF), 3),
    );
  }

  // ---- Objetos dos jogos ----

  void _memoryCard(
    Canvas c,
    Offset center,
    double angle, {
    required bool faceUp,
  }) {
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(angle);
    final outer = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 66, height: 86),
      const Radius.circular(10),
    );
    _outlined(c, Path()..addRRect(outer), Colors.white);
    final inner = outer.deflate(7);
    if (faceUp) {
      c.drawRRect(inner, Paint()..color = const Color(0xFFFFF1DC));
      _apple(c, const Offset(0, 4));
    } else {
      c.drawRRect(inner, Paint()..color = const Color(0xFFFF8A4C));
      _text(c, '?', const Offset(0, 1), 44, Colors.white);
    }
    c.restore();
  }

  void _apple(Canvas c, Offset center) {
    c.drawLine(
      center.translate(0, -12),
      center.translate(2, -22),
      _stroke(_outline, 3.5),
    );
    final shape = Path.combine(
      PathOperation.union,
      Path()..addOval(
        Rect.fromCenter(center: center.translate(-7, 0), width: 24, height: 30),
      ),
      Path()..addOval(
        Rect.fromCenter(center: center.translate(7, 0), width: 24, height: 30),
      ),
    );
    _outlined(c, shape, const Color(0xFFEF4B45), width: 3);
    final leaf = Path()
      ..moveTo(center.dx + 2, center.dy - 18)
      ..quadraticBezierTo(
        center.dx + 10,
        center.dy - 28,
        center.dx + 18,
        center.dy - 22,
      )
      ..quadraticBezierTo(
        center.dx + 10,
        center.dy - 14,
        center.dx + 2,
        center.dy - 18,
      )
      ..close();
    _outlined(c, leaf, const Color(0xFF5DBB4C), width: 2.5);
    c.drawOval(
      Rect.fromCenter(center: center.translate(-9, -4), width: 5, height: 9),
      Paint()..color = const Color(0x99FFFFFF),
    );
  }

  /// Bloquinho de letra com a "lateral" mais escura embaixo.
  void _block(
    Canvas c,
    Offset center,
    double s,
    Color base,
    String letter, {
    double angle = 0,
  }) {
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(angle);
    final face = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, -s * 0.05), width: s, height: s * 0.9),
      Radius.circular(s * 0.2),
    );
    final side = face.shift(Offset(0, s * 0.1));
    _outlined(c, Path()..addRRect(side), Color.lerp(base, Colors.black, 0.25)!);
    _outlined(c, Path()..addRRect(face), base);
    _text(c, letter, Offset(0, -s * 0.05), s * 0.6, Colors.white);
    c.restore();
  }

  /// Lacuna da palavra, onde a letra vai encaixar.
  void _slot(Canvas c, Offset center, double s) {
    final face = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: s, height: s),
      Radius.circular(s * 0.2),
    );
    c.drawRRect(face, Paint()..color = Colors.white.withValues(alpha: 0.7));
    c.drawRRect(face, _stroke(_outline.withValues(alpha: 0.45), 3));
  }

  void _speechBubble(Canvas c, Rect rect, String letter, Color accent) {
    final path = Path.combine(
      PathOperation.union,
      Path()
        ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(34))),
      Path()
        ..moveTo(rect.right - 70, rect.bottom - 6)
        ..lineTo(rect.right - 32, rect.bottom + 36)
        ..lineTo(rect.right - 40, rect.bottom - 6)
        ..close(),
    );
    _outlined(c, path, Colors.white);
    _text(c, letter, rect.center.translate(0, 2), 72, accent);
  }

  /// Estrelinha de 4 pontas.
  void _sparkle(Canvas c, Offset center, double r) {
    final p = Path()..moveTo(center.dx, center.dy - r);
    for (var i = 1; i <= 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      p.quadraticBezierTo(
        center.dx,
        center.dy,
        center.dx + r * math.cos(a),
        center.dy + r * math.sin(a),
      );
    }
    p.close();
    _outlined(c, p, const Color(0xFFFFD84D), width: 2.5);
  }

  // ---- Utilitários de desenho ----

  /// Preenchimento chapado + contorno marrom: o estilo de todo o card.
  void _outlined(Canvas c, Path path, Color fill, {double width = _line}) {
    c.drawPath(path, Paint()..color = fill);
    c.drawPath(path, _stroke(_outline, width));
  }

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _text(Canvas c, String text, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          fontFamily: fontFamily,
          fontWeight: FontWeight.w900,
          color: color,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }
}
