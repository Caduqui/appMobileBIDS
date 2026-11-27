import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/audioplayers_backend.dart';
import 'audio/game_audio.dart';
import 'screens/home_screen.dart';
import 'widgets/background_music.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Som de verdade só aqui: os testes montam as telas sem passar pelo main()
  // e ficam com o GameAudio mudo (lá não há plugin nativo). Ver lib/audio/.
  GameAudio.instance.start(AudioplayersBackend());

  // Retrato e paisagem liberados: celular e tablet, nas duas orientações.
  // As telas (home_screen, memory_game_screen, completion_game_screen etc.)
  // adaptam o layout conforme MediaQuery — ver lib/utils/responsive.dart.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
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
      theme: ThemeData(primarySwatch: Colors.teal, fontFamily: 'Roboto'),
      // Pra música de fundo saber quando uma tela volta a ficar por cima.
      navigatorObservers: [musicRouteObserver],
      home: const HomeScreen(),
    );
  }
}
