import 'package:flutter/material.dart';

class GameController {
  static bool validar(List<Offset> userPoints, List<Offset> targets) {
    int hits = 0;

    for (var target in targets) {
      for (var p in userPoints) {
        if ((p - target).distance < 25) {
          hits++;
          break;
        }
      }
    }
    return hits / targets.length > 0.8;
  }
}
