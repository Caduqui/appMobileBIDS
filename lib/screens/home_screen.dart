import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'minigames_screen.dart';

const _skyColor = Color(0xFF82CFFE);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // A arte é vertical (9:16), mas celulares modernos são mais altos (20:9).
    // Com BoxFit.cover as laterais seriam cortadas (árvore/cachorro), então a
    // imagem entra inteira na largura da tela, colada embaixo, e a sobra em
    // cima é preenchida com a cor do céu (a mesma da borda superior da arte).
    return Scaffold(
      backgroundColor: _skyColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/images/background/home.png',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HomeButton(
                  label: 'Iniciar',
                  color: Colors.orange,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MinigamesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _HomeButton(
                  label: 'Sair',
                  color: Colors.red.shade400,
                  // Fecha o app no Android. No iOS o sistema não permite que
                  // um app se feche sozinho, então lá o botão não faz nada.
                  onPressed: () => SystemNavigator.pop(),
                ),
              ],
            ),
          ),
        ],
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
    return SizedBox(
      width: 220,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
