import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguagens/data/completion_phases.dart';
import 'package:linguagens/data/letter_phases.dart';
import 'package:linguagens/data/memory_phases.dart';
import 'package:linguagens/main.dart';
import 'package:linguagens/models/difficulty.dart';
import 'package:linguagens/screens/completion_game_screen.dart';
import 'package:linguagens/screens/letter_picker_screen.dart';
import 'package:linguagens/screens/letter_sounds_screen.dart';
import 'package:linguagens/models/mouth_pose.dart';
import 'package:linguagens/screens/memory_game_screen.dart';
import 'package:linguagens/widgets/minigame_art.dart';
import 'package:linguagens/widgets/mouth_view.dart';

// Tamanhos físicos a devicePixelRatio 3.0 (ver _useDevice). O app agora
// precisa funcionar nessas 4 combinações — ver lib/utils/responsive.dart.
const _devicePortraitPhone = Size(1080, 2400); // 360x800 lógicos
const _deviceLandscapePhone = Size(2400, 1080); // 800x360 lógicos
const _devicePortraitTablet = Size(2400, 3600); // 800x1200 lógicos (>=600 = tablet)
const _deviceLandscapeTablet = Size(3600, 2400); // 1200x800 lógicos

void _useDevice(WidgetTester tester, Size physicalSize) {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// Tela de celular em pé (360x800 lógicos), que é o alvo histórico do app.
void _usePhoneScreen(WidgetTester tester) => _useDevice(tester, _devicePortraitPhone);

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

  testWidgets('cards dos jogos: centralizados e com a proporção da arte (sem corte)', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(const MemoryGameApp());
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();

    const screenWidth = 360.0;
    // No celular em pé cabe 1 card por linha, então todos ficam no centro.
    for (final kind in MinigameArtKind.values) {
      final art = find.byWidgetPredicate((w) => w is MinigameArt && w.kind == kind);
      await tester.ensureVisible(art);
      await tester.pumpAndSettle();
      final rect = tester.getRect(art);
      expect(rect.width / rect.height, closeTo(MinigameArt.aspectRatio, 0.01), reason: '$kind');
      expect(rect.center.dx, closeTo(screenWidth / 2, 1), reason: '$kind descentralizado');
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

  testWidgets('lobby em paisagem: imagem e botões lado a lado, sem overflow', (tester) async {
    _useDevice(tester, _deviceLandscapePhone);
    await tester.pumpWidget(const MemoryGameApp());
    await tester.pump();

    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);

    // Em paisagem a imagem é dimensionada pela altura da tela (não mais
    // "colada embaixo" na largura inteira, que cortaria quase tudo de uma
    // arte vertical numa tela baixa).
    final image = tester.getRect(assetImage('assets/images/background/home.png'));
    expect(image.height, closeTo(360, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('navegação em tablet retrato, sem overflow', (tester) async {
    _useDevice(tester, _devicePortraitTablet);
    await tester.pumpWidget(const MemoryGameApp());
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();
    expect(find.text('Jogo da Memória'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Jogo da Memória'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Fácil'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('navegação em tablet paisagem, sem overflow', (tester) async {
    _useDevice(tester, _deviceLandscapeTablet);
    await tester.pumpWidget(const MemoryGameApp());
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();
    expect(find.text('Complete a Palavra'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Complete a Palavra'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Difícil'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('grid da memória inverte colunas/linhas em paisagem', (tester) async {
    _useDevice(tester, _deviceLandscapePhone);
    await tester.pumpWidget(MaterialApp(
      home: MemoryGameScreen(difficulty: Difficulty.easy, phaseIndex: 0),
    ));
    await tester.pump();

    final delegate = tester.widget<GridView>(find.byType(GridView)).gridDelegate
        as SliverGridDelegateWithFixedCrossAxisCount;
    // Fácil é 3 colunas x 4 linhas em retrato; numa tela mais larga que alta
    // o grid inverte pra 4 colunas x 3 linhas (mesmo total de 12 cards) pra
    // elas não ficarem esticadas horizontalmente.
    expect(delegate.crossAxisCount, Difficulty.easy.memoryRows);

    // Descarta a tela e deixa o timer de preview (4s) terminar — senão o
    // teste falha por "pending timers" mesmo sem nada de errado no layout.
    await tester.pump(Duration(seconds: Difficulty.easy.previewSeconds + 1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('grid da memória mantém colunas originais em retrato', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(MaterialApp(
      home: MemoryGameScreen(difficulty: Difficulty.easy, phaseIndex: 0),
    ));
    await tester.pump();

    final delegate = tester.widget<GridView>(find.byType(GridView)).gridDelegate
        as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, Difficulty.easy.memoryColumns);

    await tester.pump(Duration(seconds: Difficulty.easy.previewSeconds + 1));
    await tester.pumpWidget(const SizedBox());
  });

  // Renderiza todas as fases dos dois jogos nas 4 combinações de dispositivo
  // (celular/tablet x retrato/paisagem) pra pegar overflow de layout (nomes/
  // palavras longas, grade invertida em paisagem etc.). O nº de fases varia
  // por dificuldade (ver _expectedPhaseCounts em game_data_test.dart), então
  // o loop lê o tamanho real de cada lista em vez de um número fixo.
  const deviceConfigs = {
    'celular retrato': _devicePortraitPhone,
    'celular paisagem': _deviceLandscapePhone,
    'tablet retrato': _devicePortraitTablet,
    'tablet paisagem': _deviceLandscapeTablet,
  };

  for (final deviceEntry in deviceConfigs.entries) {
    for (final difficulty in Difficulty.values) {
      final memoryPhaseCount = kMemoryPhases[difficulty]!.length;
      for (var i = 0; i < memoryPhaseCount; i++) {
        testWidgets(
            'memória ${difficulty.label} fase ${i + 1} (${deviceEntry.key}) renderiza sem erro',
            (tester) async {
          _useDevice(tester, deviceEntry.value);
          await tester.pumpWidget(MaterialApp(
            home: MemoryGameScreen(difficulty: difficulty, phaseIndex: i),
          ));
          await tester.pump();

          expect(find.byType(GridView), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.pump(Duration(seconds: difficulty.previewSeconds + 1));
          await tester.pumpWidget(const SizedBox());
        });
      }

      final completionPhaseCount = kCompletionPhases[difficulty]!.length;
      for (var i = 0; i < completionPhaseCount; i++) {
        testWidgets(
            'completar ${difficulty.label} fase ${i + 1} (${deviceEntry.key}) renderiza sem erro',
            (tester) async {
          _useDevice(tester, deviceEntry.value);
          await tester.pumpWidget(MaterialApp(
            home: CompletionGameScreen(difficulty: difficulty, phaseIndex: i),
          ));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(kCompletionPhases[difficulty]![i].words, isNotEmpty);
        });
      }
    }

    // Sons das Letras não tem dificuldade: o menu de letras e cada uma das
    // 26 letras, em todos os dispositivos.
    testWidgets('menu de letras A–Z (${deviceEntry.key}) cabe sem rolar e sem erro', (tester) async {
      _useDevice(tester, deviceEntry.value);
      await tester.pumpWidget(const MaterialApp(home: LetterPickerScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);

      final size = tester.view.physicalSize / tester.view.devicePixelRatio;
      for (final phase in kLetterPhases) {
        final rect = tester.getRect(find.text('${phase.letter}${phase.letter.toLowerCase()}'));
        expect(rect.bottom, lessThanOrEqualTo(size.height), reason: '${phase.letter} fora da tela');
        expect(rect.right, lessThanOrEqualTo(size.width), reason: '${phase.letter} fora da tela');
      }
    });

    for (var i = 0; i < kLetterPhases.length; i++) {
      final phase = kLetterPhases[i];
      testWidgets(
          'sons das letras ${phase.title} (${deviceEntry.key}) renderiza sem erro',
          (tester) async {
        _useDevice(tester, deviceEntry.value);
        await tester.pumpWidget(MaterialApp(
          home: LetterSoundsScreen(phaseIndex: i),
        ));
        await _letVideoLoad(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('${phase.letter}${phase.letter.toLowerCase()}'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      });
    }
  }

  testWidgets('Home → jogos → Sons das Letras abre direto o A–Z → letra M', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(const MemoryGameApp());
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();

    // Terceiro card: em celular retrato fica abaixo dos outros dois.
    await tester.ensureVisible(find.text('Sons das Letras'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sons das Letras'));
    await tester.pumpAndSettle();

    // Sem escolha de dificuldade: todas as letras na mesma tela.
    expect(find.byType(LetterPickerScreen), findsOneWidget);
    for (final d in Difficulty.values) {
      expect(find.text(d.label), findsNothing);
    }
    expect(find.text('Aa'), findsOneWidget);
    expect(find.text('Zz'), findsOneWidget);

    await tester.tap(find.text('Mm'));
    await tester.pumpAndSettle();
    await _letVideoLoad(tester);
    expect(find.byType(LetterSoundsScreen), findsOneWidget);
    expect(find.text('Sons das Letras — Letra M'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('sons das letras: "Próxima letra" segue o alfabeto inteiro e some no Z', (tester) async {
    _usePhoneScreen(tester);
    // Começa no I, que antes era o fim do bloco Fácil: tem que ir pro J.
    final index = kLetterPhases.indexWhere((p) => p.letter == 'I');
    await tester.pumpWidget(MaterialApp(home: LetterSoundsScreen(phaseIndex: index)));
    await _letVideoLoad(tester);

    await tester.tap(find.text('Próxima letra'));
    await tester.pumpAndSettle();
    await _letVideoLoad(tester);
    expect(find.text('Sons das Letras — Letra J'), findsOneWidget);

    // Desmonta antes: senão o MaterialApp novo reaproveita o Navigator,
    // que continua mostrando o J.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(MaterialApp(
      home: LetterSoundsScreen(phaseIndex: kLetterPhases.length - 1),
    ));
    await _letVideoLoad(tester);
    expect(find.text('Sons das Letras — Letra Z'), findsOneWidget);
    expect(find.text('Próxima letra'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('sons das letras: sem vídeo gravado mostra a boquinha animada e as palavras', (tester) async {
    _usePhoneScreen(tester);
    // "W" é a letra com menos chance de um dia ganhar vídeo gravado; se
    // ganhar, este teste é que precisa trocar de letra.
    final index = kLetterPhases.indexWhere((p) => p.letter == 'W');
    await tester.pumpWidget(MaterialApp(
      home: LetterSoundsScreen(phaseIndex: index),
    ));
    await _letVideoLoad(tester);

    expect(find.byType(MouthView), findsOneWidget);
    for (final word in kLetterPhases[index].words) {
      expect(find.text(word.name, findRichText: true), findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('sons das letras: a boquinha se mexe ao tocar e volta ao repouso', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(
      home: LetterSoundsScreen(phaseIndex: 0),
    ));
    await _letVideoLoad(tester);
    // Deixa a animação automática da abertura terminar.
    await tester.pump(const Duration(seconds: 3));

    MouthPose pose() => tester.widget<MouthView>(find.byType(MouthView)).pose;
    expect(pose().lips, 0);

    await tester.tap(find.text('Ouvir de novo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(pose().lips, closeTo(1, 0.05), reason: 'no meio do som do "A" a boca está toda aberta');

    await tester.pump(const Duration(seconds: 2));
    expect(pose().lips, 0);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('sons das letras: o H avisa que não tem som', (tester) async {
    _usePhoneScreen(tester);
    final index = kLetterPhases.indexWhere((p) => p.letter == 'H');
    await tester.pumpWidget(MaterialApp(
      home: LetterSoundsScreen(phaseIndex: index),
    ));
    await _letVideoLoad(tester);

    expect(find.text('O H não tem som'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('completar: letra errada fica vermelha e treme, depois volta', (tester) async {
    _usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(
      home: CompletionGameScreen(difficulty: Difficulty.easy, phaseIndex: 0),
    ));
    await tester.pump();

    // As letras "de enfeite" da bandeja nunca estão na palavra: qualquer uma
    // delas é uma letra errada, e só aparece na bandeja (não nas casinhas).
    final word = kCompletionPhases[Difficulty.easy]![0].words.first.name.toUpperCase();
    final wrong = find.byWidgetPredicate((w) =>
        w is Text &&
        w.data != null &&
        RegExp(r'^[A-Z]$').hasMatch(w.data!) &&
        !word.contains(w.data!));
    expect(wrong, findsWidgets);
    final tile = wrong.first;
    Color tileColor() {
      final box = tester.widget<AnimatedContainer>(
        find.ancestor(of: tile, matching: find.byType(AnimatedContainer)),
      );
      return (box.decoration! as BoxDecoration).color!;
    }

    expect(tileColor(), Colors.teal);
    await tester.tap(tile);
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 100));
    final shake = tester.widget<Transform>(
      find.ancestor(of: tile, matching: find.byType(Transform)).first,
    );
    expect(shake.transform.getTranslation().x, isNot(0.0), reason: 'tremendo');

    await tester.pump(const Duration(milliseconds: 100));
    expect(tileColor(), Colors.red);

    await tester.pump(const Duration(seconds: 1));
    expect(tileColor(), Colors.teal, reason: 'volta ao normal depois do aviso');

    await tester.pumpWidget(const SizedBox());
  });
}

/// O manifesto de assets é lido de verdade (I/O real), que o relógio falso
/// do testWidgets não avança sozinho — runAsync deixa a leitura terminar.
Future<void> _letVideoLoad(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}
