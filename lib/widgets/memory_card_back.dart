import 'package:flutter/material.dart';

import 'capybara_drawing.dart';

/// Verso das cartas do Jogo da Memória: a capivara mascote num medalhão
/// branco, sobre o azul clarinho do card da memória na tela de escolha de
/// jogo — o usuário pediu a capivara também aqui no lugar da arte antiga.
///
/// Desenhado em código porque a carta muda de proporção conforme a grade
/// (3×4, 4×3, celular, tablet): tudo é medido pelo lado menor, então o
/// medalhão fica sempre redondo e inteiro, sem corte.
class MemoryCardBack extends StatelessWidget {
  const MemoryCardBack({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _BackPainter(), child: SizedBox.expand());
  }
}

// Mesmo azul da borda do card da memória em minigame_art.dart.
const _accent = Color(0xFF4FA8F0);

class _BackPainter extends CustomPainter {
  const _BackPainter();

  @override
  void paint(Canvas c, Size size) {
    final s = size.shortestSide;
    final full = Offset.zero & size;
    c.drawRect(full, Paint()..color = Color.lerp(_accent, Colors.white, 0.78)!);

    // Bolinhas claras em grade: textura de verso de carta.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.6);
    final step = s * 0.17;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        c.drawCircle(Offset(x, y), s * 0.022, dot);
      }
    }

    // Moldura interna na cor do jogo.
    c.drawRRect(
      RRect.fromRectAndRadius(
        full.deflate(s * 0.07),
        Radius.circular(s * 0.08),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03
        ..color = _accent,
    );

    // Medalhão com a capivara. O quadro dela (ver CapybaraDrawing) cabe num
    // círculo de raio 95 centrado em (0, -10); o corpo, que desce além
    // disso, fica recortado pelo círculo.
    final center = size.center(Offset.zero);
    final radius = s * 0.36;
    final scale = radius / 95;
    final circle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    c.drawPath(circle, Paint()..color = Colors.white);
    c.save();
    c.clipPath(circle);
    const CapybaraDrawing().paint(c, center + Offset(0, 10 * scale), scale);
    c.restore();
    c.drawPath(
      circle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = CapybaraDrawing.line * scale * 1.2
        ..color = CapybaraDrawing.outline,
    );
  }

  @override
  bool shouldRepaint(_BackPainter oldDelegate) => false;
}
