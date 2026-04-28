import 'package:flutter/material.dart';
import 'draw_painter.dart';

class TraceLayer extends StatefulWidget {
  final Function(List<Offset>) onFinish;

  const TraceLayer({required this.onFinish});

  @override
  _TraceLayerState createState() => _TraceLayerState();
}

class _TraceLayerState extends State<TraceLayer> {
  List<Offset> points = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          points.add(details.localPosition);
        });
      },
      onPanEnd: (_) {
        widget.onFinish(points);
      },
      child: CustomPaint(painter: DrawPainter(points), size: Size.infinite),
    );
  }
}
