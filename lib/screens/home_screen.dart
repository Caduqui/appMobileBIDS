import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/game_audio.dart';
import '../utils/responsive.dart';
import '../widgets/background_music.dart';
import 'minigames_screen.dart';

const _skyColor = Color(0xFF82CFFE);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _HomeButton(
        label: 'Iniciar',
        color: Colors.orange,
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const MinigamesScreen()));
        },
      ),
      const SizedBox(height: 20, width: 20),
      _HomeButton(
        label: 'Sair',
        color: Colors.red.shade400,
        // Fecha o app no Android. No iOS o sistema não permite que um app
        // se feche sozinho, então lá o botão não faz nada.
        onPressed: () => SystemNavigator.pop(),
      ),
    ];

    final image = Image.asset(
      'assets/images/background/home.png',
      fit: isLandscape(context) ? BoxFit.fitHeight : BoxFit.fitWidth,
      width: isLandscape(context) ? null : double.infinity,
      height: isLandscape(context) ? double.infinity : null,
    );

    return BackgroundMusic(
      track: MusicTrack.menu,
      child: Scaffold(
        backgroundColor: _skyColor,
        body: isLandscape(context)
            // A arte é vertical (9:16): em paisagem ela não cabe "deitada" sem
            // cortar muito, então ela fica encostada num dos lados (dimensionada
            // pela ALTURA da tela) e os botões ficam no espaço que sobra.
            ? Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: buttons,
                      ),
                    ),
                  ),
                  Align(alignment: Alignment.bottomCenter, child: image),
                ],
              )
            // Em retrato ela entra inteira na largura da tela, colada embaixo;
            // a sobra em cima é preenchida pela cor do céu (a mesma da borda
            // superior da arte), e os botões ficam centralizados nessa sobra.
            : Stack(
                fit: StackFit.expand,
                children: [
                  Align(alignment: Alignment.bottomCenter, child: image),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: buttons,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _HomeButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final width = responsiveValue(context, phone: 220.0, tablet: 320.0);
    final fontSize = responsiveValue(context, phone: 22.0, tablet: 28.0);
    final vPadding = responsiveValue(context, phone: 20.0, tablet: 26.0);

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: () {
          GameAudio.instance.play(Sfx.tap);
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: vPadding),
          textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),
        child: Text(label),
      ),
    );
  }
}
