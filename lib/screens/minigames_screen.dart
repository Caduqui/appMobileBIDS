import 'package:flutter/material.dart';

import 'memory_phases_screen.dart';

class MinigamesScreen extends StatelessWidget {
  const MinigamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: const Text('Escolha um jogo'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _MinigameCard(
                title: 'Jogo da Memória',
                imagePath: 'assets/cards/back_card.png',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MemoryPhasesScreen()),
                  );
                },
              ),
              // Novos minigames entram aqui como novos _MinigameCard.
            ],
          ),
        ),
      ),
    );
  }
}

class _MinigameCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const _MinigameCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imagePath,
                width: 160,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}