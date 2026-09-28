import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguagens/data/completion_phases.dart';
import 'package:linguagens/main.dart';
import 'package:linguagens/models/difficulty.dart';
import 'package:linguagens/screens/completion_game_screen.dart';
import 'package:linguagens/screens/memory_game_screen.dart';

/// Tela de celular em pé (360x800 lógicos), que é o alvo do app.
void _usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('Home → jogos → dificuldade → fases → jogo de completar', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(const MemoryGameApp());

    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);

    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();
    expect(find.text('Jogo da Memória'), findsOneWidget);
    expect(find.text('Complete a Palavra'), findsOneWidget);

    await tester.tap(find.text('Complete a Palavra'));
    await tester.pumpAndSettle();
    for (final d in Difficulty.values) {
      expect(find.text(d.label), findsOneWidget);
    }

    await tester.tap(find.text('Difícil'));
    await tester.pumpAndSettle();
    expect(find.text('Fase 1'), findsOneWidget);
    expect(find.text('Fase 5'), findsOneWidget);

    await tester.tap(find.text('Fase 1'));
    await tester.pumpAndSettle();
    expect(find.text('Palavra 1 de 3'), findsOneWidget);
  });

  testWidgets('Home → jogo da memória → fácil → fase 1 mostra 12 cards', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(const MemoryGameApp());

    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jogo da Memória'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fácil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fase 1'));
    // pump com duração (e não pumpAndSettle) pra concluir a transição de
    // rota sem deixar o preview de 4s virar as cartas.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // No preview todas as cartas estão viradas: 6 nomes x 2 cartas.
    expect(find.text('Banana'), findsNWidgets(2));
    expect(find.text('Abacaxi'), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox()); // descarta a tela e seus timers
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('cards de fase ficam centralizados na horizontal', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(const MemoryGameApp());
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jogo da Memória'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fácil'));
    await tester.pumpAndSettle();

    final rects = [
      for (var i = 1; i <= 5; i++) tester.getRect(find.text('Fase $i')),
    ];
    // Só as duas primeiras fases (mesma linha) já bastam pra ver a simetria.
    final left = rects.map((r) => r.left).reduce((a, b) => a < b ? a : b);
    final right = rects.map((r) => r.right).reduce((a, b) => a > b ? a : b);
    final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(left, closeTo(screenWidth - right, 40)); // rótulo é mais estreito que o card
  });

  Finder assetImage(String name) => find.byWidgetPredicate(
        (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == name,
      );

  testWidgets('cards dos jogos: centralizados e com a proporção da imagem (sem corte)', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(const MemoryGameApp());
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();

    const screenWidth = 360.0;
    final cards = {
      'assets/cards/back_card.png': 1011 / 1432,
      'assets/cards/completePalavra.jpg': 1251 / 1886,
    };
    for (final entry in cards.entries) {
      final rect = tester.getRect(assetImage(entry.key));
      expect(rect.width / rect.height, closeTo(entry.value, 0.01), reason: entry.key);
      expect(rect.center.dx, closeTo(screenWidth / 2, 1), reason: '${entry.key} descentralizado');
    }
    expect(find.text('Complete a Palavra'), findsOneWidget);
  });

  testWidgets('lobby: imagem inteira na largura da tela, botões no centro vertical', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(const MemoryGameApp());
    await tester.pump();

    final image = tester.getRect(assetImage('assets/images/background/home.png'));
    expect(image.width, 360);
    expect(image.width / image.height, closeTo(1080 / 1920, 0.01));
    expect(image.bottom, closeTo(800, 0.5)); // colada embaixo, sem faixa sobrando

    // O bloco Iniciar+Sair fica no centro da tela (800 / 2 = 400).
    final start = tester.getRect(find.text('Iniciar'));
    final exit = tester.getRect(find.text('Sair'));
    final blockCenterY = (start.top + exit.bottom) / 2;
    expect(blockCenterY, closeTo(400, 8));
    expect(start.center.dx, closeTo(180, 1));
    expect(tester.takeException(), isNull);
  });

  // Renderiza todas as fases em tela de celular pra pegar overflow de layout
  // (nomes/palavras longas, grade 4x5 etc.).
  for (final difficulty in Difficulty.values) {
    for (var i = 0; i < 5; i++) {
      testWidgets('memória ${difficulty.label} fase ${i + 1} renderiza sem erro', (tester) async {
        _usePhoneScreen(tester);
        await tester.pumpWidget(MaterialApp(
          home: MemoryGameScreen(difficulty: difficulty, phaseIndex: i),
        ));
        await tester.pump();

        expect(find.byType(GridView), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pump(Duration(seconds: difficulty.previewSeconds + 1));
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('completar ${difficulty.label} fase ${i + 1} renderiza sem erro', (tester) async {
        _usePhoneScreen(tester);
        await tester.pumpWidget(MaterialApp(
          home: CompletionGameScreen(difficulty: difficulty, phaseIndex: i),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(kCompletionPhases[difficulty]![i].words, isNotEmpty);
      });
    }
  }
}
