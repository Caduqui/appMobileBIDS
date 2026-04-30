import 'package:flutter/material.dart';
import 'draw_painter.dart';

class TraceLayer extends StatefulWidget {
  final Function(List<Offset>) onFinish;
  //recebe uma função que será chamada quando terminar o desenho

  const TraceLayer({required this.onFinish});

  @override
  _TraceLayerState createState() => _TraceLayerState();
}

class _TraceLayerState extends State<TraceLayer> {
  List<Offset> points = [];
  //guarda os pontos desenhados

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //captura o toque
      onPanUpdate: (details) {
        setState(() {
          points.add(details.localPosition);
        });
      },
      //adiciona a posição do dedo enquanto arrasta
      onPanEnd: (_) {
        widget.onFinish(points);
      },
      //quando solta chama a função da tela
      child: CustomPaint(
        painter: DrawPainter(points),
        size: Size.infinite,
      ), //desenha o traço
    );
  }
}
