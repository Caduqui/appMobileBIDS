import 'package:flutter/material.dart';

class GameController {
  //classe responsável pela lógica do jogo (validação)

  static bool validar(List<Offset> userPoints, List<Offset> targets) {
    //método estático que permite ser chamado sem instanciar a classe
    //userPoints = pontos desenhados pelo usuário
    // targets = pontos corretos da letra

    int hits = 0;

    for (var target in targets) {
      //percorre cada ponto correto da letra
      for (var p in userPoints) {
        //percore todos os pontos desenhados pelo usuário
        if ((p - target).distance < 25) {
          //verifica se o ponto do usuário está perto do ponto correto
          hits++;
          break;
        }
      }
    }
    return hits / targets.length >
        0.8; //retorna verdadeiro se acertou mais de 80% dos pontos
  }
}
