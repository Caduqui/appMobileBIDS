import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Jogo é somente em retrato.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    // Modo imersivo: esconde a barra de status (hora/bateria/wifi) e a
    // barra de navegação do Android. "immersiveSticky" permite que o
    // usuário puxe a borda pra revelar as barras temporariamente se
    // precisar, e elas escondem de novo sozinhas.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    runApp(const MemoryGameApp());
  });
}

class MemoryGameApp extends StatelessWidget {
  const MemoryGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fase 1 — Jogo da Memória',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}