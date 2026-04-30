import 'package:ensinolinguagens/data/letters_data.dart';
import 'package:flutter/material.dart';
import '../controllers/game_controller.dart';
import '../widgets/trace_layer.dart';
import '../widgets/draw_painter.dart';

class AlphabetScreen extends StatefulWidget {
  //StatefulWidget porque a tela muda (desenho do usuário)
  @override
  _AlphabetScreenState createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  List<Offset> userPoints = [];
  //Lista que guarda onde o usuário passou o dedo

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //estrutura base da tela
      body: Stack(
        children: [
          //permite sobrepor elementos (fundo, letra, desenho)
          Positioned.fill(
            child: Container(color: Colors.blue), // Placeholder para fundo
          ),

          Center(
            child: Text(
              'Letra A',
              style: TextStyle(fontSize: 50, color: Colors.white),
            ),
          ), // Placeholder para letra central(depois vira imagem)

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
