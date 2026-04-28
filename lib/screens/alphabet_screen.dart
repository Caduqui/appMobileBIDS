import 'package:ensinolinguagens/data/letters_data.dart';
import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../widgets/trace_layer.dart';
import '../widgets/draw_painter.dart';

class AlphabetScreen extends StatefulWidget {
  @override
  _AlphabetScreenState createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  List<Offset> userPoints = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.blue), // Placeholder para fundo
          ),

          Center(
            child: Text(
              'Letra A',
              style: TextStyle(fontSize: 50, color: Colors.white),
            ),
          ), // Placeholder para letra

          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                userPoints.add(details.localPosition);
              });
            },
            onPanEnd: (_) {
              _verifyProgress();
            },
            child: CustomPaint(
              painter: DrawPainter(userPoints),
              size: Size.infinite,
            ),
          ),
          TraceLayer(
            onFinish: (points) {
              bool isCorrect = GameController.validar(points, pointsA);

              if (isCorrect) {
                print("Parabéns! Você acertou a letra A!");
              } else {
                print("Tente novamente! Você não acertou a letra A.");
              }
            },
          ),
        ],
      ),
    );
  }

  void _verifyProgress() {
    bool isCorrect = GameController.validar(userPoints, pointsA);

    if (isCorrect) {
      print("Parabéns! Você acertou a letra A!");
    } else {
      print("Tente novamente! Você não acertou a letra A.");
    }
  }
}
