import 'package:flutter/material.dart';

import 'memory_game_screen.dart';

class MemoryPhasesScreen extends StatelessWidget {
  const MemoryPhasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        title: const Text('Jogo da Memória'),
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
              _PhaseCard(
                label: 'Fase 1',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MemoryGameScreen()),
                  );
                },
              ),
              // Novas fases entram aqui como novos _PhaseCard.
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PhaseCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.teal,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}