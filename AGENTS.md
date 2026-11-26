# AGENTS.md

Guia para agentes de IA (e humanos) trabalhando neste repositório. Leia isto
antes de mexer no código.

## O que é o projeto

App Flutter infantil para ensinar português a crianças. Hoje tem:

- **Lobby** (`HomeScreen`) → **Escolha do jogo** (`MinigamesScreen`) →
  **Escolha de dificuldade** (`DifficultyScreen`) → **Escolha de fase**
  (`PhasesScreen`) → **Jogo**.
- Dois minigames implementados: **Jogo da Memória** e **Complete a Palavra**.
  Cada um tem 3 dificuldades (Fácil/Médio/Difícil), com 8 fases no Fácil e no
  Médio e 7 no Difícil (ver `_expectedPhaseCounts` em
  `test/game_data_test.dart`), cobrindo temas como frutas, animais, objetos
  escolares, brinquedos, transportes, comidas, higiene e emoções. O nº de
  fases não precisa ser igual entre dificuldades — o Difícil tem 1 fase a
  menos porque "Transportes" só existe lá uma vez (não duplicamos tema dentro
  da mesma dificuldade).
- Terceiro minigame: **Sons das Letras**. Uma letra por fase, em ordem
  alfabética (Fácil A–I, Médio J–R, Difícil S–Z): a letra grande de um lado
  e, ao lado, a **"boquinha"** (termo da fonoaudiologia, Método das
  Boquinhas) fazendo o som da letra ("mmm", "fff" — o som, não o nome
  "eme", "efe"), mais **2 ou 3 palavras de exemplo** que têm a letra (no
  começo, meio ou fim, como nos slides do método). A
  boquinha é uma foto real de boca, animada em código, com o áudio do som tocando
  junto; ver "Boquinhas e áudios" abaixo.
- Existe também uma tela de alfabetização (traçar letras) que foi **começada
  e depois toda comentada** — ver seção "Código morto" abaixo.
- O app roda em celular e tablet, retrato e paisagem (as 4 orientações estão
  liberadas em `main.dart`). Ver "Responsividade" abaixo antes de mexer em
  qualquer tela.

Comentários no código são em português e explicam o "porquê", não o "o quê".
Mantenha esse padrão ao editar.

## Comandos essenciais

```
flutter pub get        # instalar dependências
flutter analyze        # lint estático — deve ficar limpo (ver exceção abaixo)
flutter test           # roda toda a suíte (~325 testes, ~20s)
flutter run             # roda em device/emulador conectado
flutter build apk --release   # gera o APK para instalar manualmente
```

O Flutter deste ambiente é o 3.44.9 (stable), instalado em
`~/Downloads/flutter_windows_3.44.9-stable`(ou já no PATH). Rode `flutter
doctor` se algo parecer errado com o toolchain. O app usa plugin nativo
(`video_player`), e no Windows o Flutter só compila app com plugin se o
**Modo de Desenvolvedor** estiver ligado (`start ms-settings:developers`) —
sem ele, `flutter run`/`build` falha pedindo "symlink support".

**Sempre rode `flutter analyze` e `flutter test` antes de considerar uma
mudança pronta.** `flutter analyze` deve mostrar só os 2 avisos pré-existentes
em `lib/widgets/trace_layer.dart` (arquivo do código morto, não mexa nele —
ver abaixo). Qualquer outro warning/erro é seu.

## Arquitetura

Camadas, de baixo para cima — cada uma só conhece a de baixo:

```
models/        — classes de dados imutáveis + enums. Sem lógica de jogo.
data/          — catálogo de vocabulário + fases (dados estáticos, const).
controllers/   — ChangeNotifier com a lógica de cada jogo. Sem Flutter widgets.
widgets/       — peças de UI reutilizáveis entre telas.
screens/       — telas (StatelessWidget de navegação / StatefulWidget de jogo).
utils/         — helpers sem estado (hoje só responsividade).
```

### models/

- `word_item.dart` — `WordItem`: uma palavra do vocabulário (fruta, animal,
  objeto...). Tem `imagePath` (PNG) OU `emoji` como ilustração — pelo menos um
  dos dois é obrigatório (`assert` no construtor). Hoje só as 8 frutas
  originais têm PNG; todo o resto usa emoji até existir arte própria.
- `difficulty.dart` — `Difficulty` (enum `easy`/`medium`/`hard`): fonte única
  de verdade pra tamanho de grade da memória (`memoryColumns`/`memoryRows`),
  tempo de preview (`previewSeconds`) e nº de letras faltando no Complete a
  Palavra (`missingLetters`). Qualquer novo minigame com níveis de dificuldade
  deveria ler daqui em vez de inventar a própria escala.
- `memory_card_model.dart` — `MemoryCardModel` + `CardState` (enum:
  `faceDown`/`faceUp`/`matched`/`mismatchError`). Imutável de propósito: o
  Flutter decide se anima o flip comparando widget antigo vs novo, e isso só
  funciona se `copyWith` sempre criar uma instância nova.
- `game_phase_status.dart` — `GamePhaseStatus`: status da fase da memória como
  um todo (`previewing`/`waitingFirstPick`/`waitingSecondPick`/
  `checkingPair`/`completed`), separado do estado por carta.
- `completion_models.dart` — `LetterSlot` (posição da palavra), `LetterTile`
  (letra na bandeja) e `CompletionStatus` (enum) para o Complete a Palavra.

### data/

- `word_catalog.dart` — classe `Words` com `static const WordItem` para cada
  palavra do vocabulário, agrupadas por tema em comentários (`// ---- Frutas
  ----`). **Para adicionar uma palavra nova, adicione aqui primeiro.**
- `memory_phases.dart` — `kMemoryPhases`: `Map<Difficulty, List<MemoryPhase>>`.
  O nº de fases por dificuldade pode variar (ver `_expectedPhaseCounts` em
  `test/game_data_test.dart`), mas cada fase precisa ter exatamente
  `difficulty.memoryPairs` itens (6/8/10) — conferido no mesmo teste. A fase
  "Frutas" do Médio é a fase 1 original do jogo (8 frutas com PNG).
- `completion_phases.dart` — `kCompletionPhases`: mesma estrutura, mas cada
  fase tem 3 palavras jogadas em sequência. Letras acentuadas (ã, ç, é...)
  nunca ficam escondidas. `difficulty.missingLetters` é um teto, não um valor
  fixo por palavra — `CompletionGameController._startWord` reduz sozinho pra
  palavras curtas demais (ex.: "Uva" no Fácil, que pede 2 lacunas mas só
  comporta 1 sem ficar com menos de 2 letras visíveis), então não precisa
  escolher só palavras compridas pra "caber" na dificuldade. **No Fácil
  especificamente**, além da regra de poucas lacunas, as palavras também
  devem ser as mais curtas e sem acento do tema (ex.: "Uva/Limão/Melão" em
  vez de "Banana/Abacaxi/Laranja", e "Uva" em vez de "Maçã") — são crianças
  que ainda não leem/escrevem, e acentuação é complexidade a mais que não
  ajuda nessa fase. "Uva" é o caso mínimo do sistema: 3 letras, 1 só lacuna.
- `letter_phases.dart` — `kLetterPhases`: uma `LetterPhase` por letra, com a
  pose da boca (`mouth`, e `release` nos sons que estouram), 2–3 `words` do
  `word_catalog.dart` e os caminhos derivados da letra (`audioPath`,
  `videoPath`). As poses ficam em constantes no topo do arquivo (`_a`,
  `_lipsClosed`, `_teethOnLip`...) e são compartilhadas por letras com a
  mesma articulação (P/B, F/V, S/Z, C/G/K/Q). A divisão alfabética foi
  escolha do usuário, não uma escala fonética.

### controllers/

Ambos são `ChangeNotifier` puro (sem import de `material.dart`), expõem
callbacks (`VoidCallback?`) pra tela disparar efeitos visuais sem o
controller conhecer widgets, e usam listas imutáveis
(`cards = [for (...) ...]`) em vez de mutar objetos existentes.

- `memory_game_controller.dart` — `MemoryGameController`. Ponto de atenção:
  usa `Future.delayed` pra preview, erro e match. Guarda um `_round` que
  incrementa em todo `startPhase()` e um `_disposed` setado em `dispose()`;
  todo callback de `Future.delayed` confere os dois antes de mexer em estado,
  senão um timer de uma rodada antiga (ex.: jogador trocou de fase ou apertou
  "jogar novamente" rápido) resolveria pares da rodada errada ou chamaria
  `notifyListeners()` num controller já descartado.
- `completion_game_controller.dart` — `CompletionGameController`. Tem
  `Random` injetável (parâmetro `random`) especificamente pra testes
  determinísticos — veja `test/completion_controller_test.dart`. Função solta
  `isBlankableLetter()` no topo do arquivo (não um método) porque o teste de
  dados (`game_data_test.dart`) também precisa dela. `_startWord` calcula o
  nº de lacunas por palavra (`missingCount`), não usa `_missingLetters`
  (o teto da dificuldade) direto — por isso `game_data_test.dart` testa o
  comportamento real instanciando o controller em vez de recalcular a
  fórmula no teste.
- `game_controller.dart` — **não usado por nenhuma tela ativa**, só pela
  `alphabet_screen.dart` comentada. Faz parte do código morto.

### screens/

Fluxo de navegação por `Navigator.push`/`pushReplacement`, sem rotas nomeadas
nem gerenciador de estado global — cada tela cria e possui seu próprio
controller em `initState`/`dispose`.

- `home_screen.dart` — lobby. Em **retrato**: fundo vertical (9:16) colado
  embaixo da tela (`Align(bottomCenter) + BoxFit.fitWidth`), resto preenchido
  com a cor do céu da própria imagem (`_skyColor`) pra emendar sem corte em
  telas mais altas que a imagem. Em **paisagem**: a imagem é alta demais pra
  caber "deitada" sem cortar muito, então vira um `Row` — imagem dimensionada
  pela altura da tela (`BoxFit.fitHeight`) de um lado, botões centralizados
  do outro (ver `isLandscape()`). Botão "Sair" usa `SystemNavigator.pop()`
  (só funciona no Android; no iOS o sistema não deixa um app se fechar
  sozinho).
- `minigames_screen.dart` — lista os minigames como cards (`_MinigameCard`).
  Cada card usa `AspectRatio` com a proporção real do arquivo de imagem (não
  um quadrado cortado) — ver "Convenção de imagens" abaixo. Largura do card e
  fonte do título escalam em tablet via `responsiveValue`.
- `difficulty_screen.dart` e `phases_screen.dart` — genéricas, servem pra
  qualquer minigame. Recebem `gameTitle`, `phaseTitlesFor` (função
  `Difficulty → List<String>`) e `gameBuilder` (função `(Difficulty, int) →
  Widget`) de quem as chama. **Um minigame novo não deveria precisar de telas
  de dificuldade/fase próprias** — só instanciar `DifficultyScreen` com os
  parâmetros certos, como `minigames_screen.dart` já faz pros dois jogos
  existentes. Botões/cards escalam em tablet (`responsiveValue`).
- `memory_game_screen.dart` — tela do jogo da memória. Recebe `difficulty` +
  `phaseIndex`, busca a fase em `kMemoryPhases`, instancia o controller e tem
  botão "Próxima fase" que faz `pushReplacement` pra `phaseIndex + 1` quando
  existe próxima fase na mesma dificuldade. O grid usa `difficulty.
  memoryColumns`/`memoryRows` como estão em telas mais altas que largas, mas
  **inverte colunas↔linhas quando `constraints.maxWidth > constraints.
  maxHeight`** (dentro do `LayoutBuilder`) — o mesmo nº de cartas, só
  organizado como 4×3 em vez de 3×4, pra elas não ficarem esticadas em
  paisagem. Num tablet, um `ConstrainedBox` limita o tamanho máximo do grid
  pra as cartas não ficarem enormes só porque sobra espaço de tela.
- `completion_game_screen.dart` — tela do Complete a Palavra, mesmo padrão de
  `difficulty`/`phaseIndex`/`pushReplacement` do jogo da memória. Em
  **retrato**, empilha tudo (`_buildPortrait`): palavra em cima (`Expanded`),
  controles embaixo. Em **paisagem**, vira um `Row` (`_buildLandscape`):
  palavra à esquerda, controles à direita dentro de um `LayoutBuilder` +
  `SingleChildScrollView` + `ConstrainedBox(minHeight) `+ `Center` — centraliza
  verticalmente quando cabe e rola em vez de estourar quando não cabe (numa
  tela de celular deitado bem baixa, o Médio/Difícil pode ter peças
  suficientes pra quebrar em 2 linhas no `Wrap` e não caber na altura). Os dois
  layouts chamam os mesmos métodos privados (`_buildWordCard`, `_buildSlots`,
  `_buildTiles`, `_buildFooter`) — ao mudar uma peça da UI, mexa no método, não
  duplique entre os dois layouts.
- `letter_sounds_screen.dart` — tela do Sons das Letras, mesmo padrão de
  `difficulty`/`phaseIndex`/`pushReplacement`. **Sem controller em
  `controllers/`**: não há regra de jogo, só tocar som e animação. A
  boquinha é um `AnimationController` da tela + `mouthPoseAt(keyframes, t)`
  desenhado por `MouthView` (foto deformada); o som é um `VideoPlayerController` do plugin
  `video_player` (que toca áudio puro também — por isso não há plugin de
  áudio separado). O som começa em `phase.soundAt` da animação, não no
  instante zero, pra casar com a boca. Tudo que é mídia é conferido no
  `AssetManifest` antes de abrir: letra sem áudio anima em silêncio, palavra
  sem áudio não faz nada ao toque. Se existir `assets/videos/letters/<letra>
  .mp4`, o vídeo gravado substitui a boquinha animada (falha ao abrir
  mostra "Não foi possível tocar o vídeo"). Letra e boca ficam sempre lado a
  lado em quadrados (`Center` + `AspectRatio(1)`); as palavras vão embaixo
  em retrato e numa terceira coluna em paisagem. Toca sozinho 700ms depois
  de abrir (fim da transição de tela) e de novo, do começo, a cada toque na
  letra, na boca ou em "Ouvir de novo". O card dessa tela em
  `minigames_screen.dart` usa um "Aa" desenhado (`art:`) por não ter arte
  própria ainda.

### widgets/

- `memory_card_widget.dart` — flip 3D (`Transform`+`rotateY`) com shake em
  erro. Frente mostra `WordImage` + nome (em `FittedBox` pra nomes longos tipo
  "Helicóptero" não estourarem a largura do card).
- `celebration_overlay.dart` / `shake_widget.dart` — mesmo padrão:
  `triggerKey` é um `int` incremental (não um `bool`), porque um bool não
  dispara a animação de novo se o valor continuar `true` entre dois acertos
  seguidos.
- `word_image.dart` — `WordImage`: desenha `item.imagePath` se existir, senão
  o `item.emoji` em `FittedBox`. É o único lugar que decide PNG-vs-emoji —
  outras telas nunca devem checar `imagePath`/`emoji` diretamente.
- `trace_layer.dart` / `draw_painter.dart` — só usados pela
  `alphabet_screen.dart` comentada. Código morto.

## Responsividade

`lib/utils/responsive.dart` é o único lugar com lógica de tamanho de tela —
toda tela nova que precisa se adaptar a celular/tablet ou retrato/paisagem
deve importar daqui, não reinventar o cálculo:

- `isTablet(context)` — `true` quando `MediaQuery.sizeOf(context).
  shortestSide >= 600` (ponto de corte do Material). Usa `shortestSide` de
  propósito: não muda ao girar o aparelho, então um tablet continua "tablet"
  em qualquer orientação.
- `isLandscape(context)` — via `MediaQuery.orientationOf(context)`.
- `responsiveValue(context, phone: x, tablet: y)` — escolhe um valor conforme
  o dispositivo. É o jeito padrão de escalar tamanho/fonte de botões e cards
  pra tablet (ver `home_screen.dart`, `minigames_screen.dart`,
  `difficulty_screen.dart`, `phases_screen.dart`, `completion_game_screen.
  dart`); em celular sempre retorna `phone`, então esse valor reproduz o
  comportamento de antes da responsividade existir.
- `maxContentWidth(context)` — `double.infinity` no celular, 900 no tablet.
  Usado como `maxWidth` de um `ConstrainedBox` centralizado em telas de
  lista/grade de cards, pra num tablet em paisagem o conteúdo não esticar até
  a borda da tela com um espaçamento gigante entre cards.

Diferente de "escalar tamanho" (que é so `responsiveValue`), **mudar a
estrutura do layout** por orientação (empilhado vs. lado a lado, colunas vs.
linhas do grid) é decisão de cada tela, geralmente ramificando em `isLandscape
(context)` ou, quando o espaço disponível importa mais que o tamanho da tela
inteira (ex.: dentro de um `LayoutBuilder` de grid), comparando `constraints.
maxWidth` com `constraints.maxHeight` diretamente — ver `memory_game_screen.
dart` e `completion_game_screen.dart`.

## Convenções que vale a pena preservar

- **Dificuldade dirige tudo:** nunca hard-code tamanho de grade, nº de
  lacunas ou tempo de preview numa tela — leia de `Difficulty`.
- **Centralizar um `Wrap`:** `Wrap` só ocupa a largura do próprio conteúdo, 
  então `WrapAlignment.center` sozinho não centraliza nada se o `Wrap` estiver
  dentro de algo que também encolhe pro conteúdo (como `Column` dentro de
  `SingleChildScrollView`). Sempre envolva com `SizedBox(width:
  double.infinity, child: Wrap(...))` — ver `minigames_screen.dart` e
  `phases_screen.dart`.
- **Imagens de card/thumbnail:** nunca usar `BoxFit.cover` num quadrado fixo
  pra arte que não é quadrada — corta título/personagem. Em vez disso, usar
  `AspectRatio(aspectRatio: larguraPx / alturaPx)` com a proporção real do
  arquivo (ver `_MinigameCard` em `minigames_screen.dart`).
- **Timers em controllers:** todo `Future.delayed` que mexe em estado precisa
  de uma guarda contra "a tela/controller já não existe mais" — copie o
  padrão `_disposed` + `_round` de `memory_game_controller.dart` em vez de só
  confiar em `mounted` (controllers não são widgets, não têm `mounted`).
- **Imutabilidade de modelo:** `copyWith` sempre retorna instância nova, nunca
  mute um campo direto — o Flutter usa `==`/identidade pra decidir animações.
- **WordItem novo:** adicione em `word_catalog.dart` primeiro (id em
  minúsculas, nome com acentuação correta), depois referencie em
  `memory_phases.dart`/`completion_phases.dart`. Se adicionar PNG próprio,
  registre a pasta em `pubspec.yaml` → `flutter: assets:` e preencha
  `imagePath` no `WordItem`.

## Boquinhas e áudios (Sons das Letras)

**Boquinha (foto real animada).** `models/mouth_pose.dart` (`MouthPose`:
abertura dos lábios, queixo, largura, bico, lábios apertados, dentes no
lábio, ponta e fundo da língua — tudo 0–1, interpolável) +
`widgets/mouth_view.dart` (`MouthView`). O usuário achou a boca desenhada
"de desenho" demais e pediu uma boca de gente real, a mesma em todas as
letras: é **uma foto só**, `assets/images/mouth/mouth.jpg` (Pexels, foto
7290083 de MART PRODUCTION, licença Pexels: uso livre, pode modificar, sem
crédito obrigatório), de frente e com os lábios fechados. O painter corta a
foto em duas malhas de triângulos (`drawVertices` + `ImageShader`) na linha
entre os lábios — lábio de cima; lábio de baixo + queixo — e cada pose
deforma as malhas (`_Rig.deform`): o vão abre no meio e fica fechado nos
cantos, o queixo desce inteiro, a boca estica (sorriso) ou estreita (bico).
Como a foto tem a boca fechada, **dentes, língua e o escuro da boca são
desenhados** por baixo das malhas e só aparecem no vão. Os pontos da linha
dos lábios (`_seam`, `_centerX`, `_halfWidth`, `_crop`) foram marcados à mão
em pixels dessa foto — **trocar a foto exige marcar de novo**. Pra mudar
como um som aparece, mexa na pose em `data/letter_phases.dart`; pra mudar a
deformação ou o interior, mexa no painter. Não dá pra julgar o resultado
lendo o código: renderize as poses num PNG (um `testWidgets` temporário
com `tester.runAsync` — a foto só decodifica com I/O real — e
`RepaintBoundary.toImage`) e olhe, inclusive ampliado.

**Áudios.** Um arquivo por letra em `assets/audio/letters/` (`a.mp3` ...
`z.mp3`, o **som** da letra) e, opcionalmente, um por palavra de exemplo em
`assets/audio/words/` (`<id da palavra>.mp3`, ex. `abelha.mp3`). As pastas
já estão no `pubspec.yaml`; o teste de dados falha se aparecer arquivo com
nome fora da convenção. Os áudios foram recortados da série "Os sons das
letras com boquinhas" do canal oficial do Método das Boquinhas (Renata
Jardini), com permissão obtida pelo usuário **só para os áudios** — as
imagens/vídeos de lá não entram no app. As palavras de exemplo também são
as dos slides de lá (por isso têm áudio). K e Q reusam o áudio do C, Y o
do I, W o do U; H não tem áudio; as palavras de H/K/Q/W/Y são nossas e
não têm áudio. Os recortes foram feitos por medição de volume, sem ouvir —
se um áudio estiver cortado errado, é só substituir o arquivo. O áudio da letra deve começar
sem silêncio no início, senão atrasa em relação à boca.

**Vídeo gravado (opcional).** `assets/videos/letters/<letra>.mp4` (H.264 +
AAC, só a boca, de frente, 1–2s) substitui a boquinha animada daquela
letra, com o som da própria gravação.

Histórico: uma primeira tentativa de boca desenhada + TTS foi descartada (o
TTS do aparelho não produz o som isolado das letras e erra sílabas soltas;
a boca não representava a fonética). Depois veio uma boca toda desenhada em
código com áudio gravado, também descartada por parecer desenho; a atual
(foto real deformada) foi escolha do usuário. Não volte pro TTS nem pra
boca 100% desenhada.

## Testes

Três arquivos em `test/`, todos relevantes — não pule a suíte:

- `game_data_test.dart` — valida os **dados**: cada dificuldade tem o nº de
  fases esperado (`_expectedPhaseCounts`, hoje 8/8/7), nº certo de itens por
  fase, ids únicos, PNGs referenciados existem de fato no disco, palavras do
  Complete a Palavra comportam as lacunas da dificuldade, alfabeto do Sons
  das Letras completo e em ordem, 2–3 palavras com a letra, áudio de toda
  letra menos o H, nomes de vídeo e áudio
  na convenção. **Qualquer fase
  nova precisa passar aqui — e se mudar a contagem de fases de alguma
  dificuldade, atualize `_expectedPhaseCounts`.**
- `completion_controller_test.dart` — testa `CompletionGameController`
  isolado (sem widgets), incluindo `Random` fixo pra determinismo, regra de
  acento nunca sumir, letra errada não preenche, avançar de palavra/fase.
- `widget_test.dart` — fluxo de navegação ponta a ponta e testes de layout
  (centralização, proporção de imagem, sem overflow). Roda **todas as fases
  dos três jogos em 4 combinações de dispositivo** (`_useDevice` +
  `_devicePortraitPhone`/`_deviceLandscapePhone`/`_devicePortraitTablet`/
  `_deviceLandscapeTablet`, todas a `devicePixelRatio: 3.0`) só pra pegar
  overflow — é a rede de segurança contra nome/palavra comprida ou grid
  invertido estourando o layout em alguma combinação de tela. **Qualquer tela
  nova, ou mudança de layout numa existente, devia entrar nesse loop** (ou
  ganhar um teste equivalente) em vez de só ser testada em celular retrato.
  Tem também testes específicos do swap de colunas/linhas do grid da memória
  (`grid da memória inverte/mantém...`) e do layout lado a lado do lobby em
  paisagem. Testes de tela do Sons das Letras chamam `_letVideoLoad(tester)`
  pra deixar a leitura (real) do `AssetManifest` terminar — o relógio falso
  do `testWidgets` não avança I/O sozinho. Ao mexer em `home_screen.dart`/
  `minigames_screen.dart`, note os testes que leem posição/tamanho via `tester.getRect` — eles fixam números
  mágicos (ex.: `screenWidth / 2`) que dependem do tamanho de tela simulado.

## Código morto — não expanda, não "arrume"

Estes arquivos são de uma feature de alfabetização (traçar letras) começada e
abandonada; estão **inteiramente comentados** ou desconectados de qualquer
tela ativa:

- `lib/screens/alphabet_screen.dart` (todo comentado)
- `lib/screens/welcome_screen.dart` (todo comentado)
- `lib/widgets/trace_layer.dart`, `lib/widgets/draw_painter.dart`
- `lib/controllers/game_controller.dart`
- `lib/data/letters_data.dart`
- `assets/images/letters/letterA.png` (não declarado em `pubspec.yaml`)

Se o usuário pedir pra retomar a tela de alfabetização, esses arquivos são o
ponto de partida. Se não, não precisa tocar neles nem "limpar" — foi decisão
deliberada deixá-los como referência futura.

## Coisas estranhas no projeto, não mude sem avisar o usuário

- **Dois `MainActivity.kt` Android:** existe
  `android/app/src/main/kotlin/com/example/ensinolinguagens/MainActivity.kt`
  (pacote antigo) e `.../com/example/linguagens/MainActivity.kt` (pacote
  atual, usado pelo `applicationId` em `android/app/build.gradle.kts`). O
  primeiro é resto de um rename do projeto; não afeta o build mas é lixo.
- **`pubspec.yaml` `assets:`** lista `assets/fruits/`, `assets/cards/`, `assets/images/mouth/` e
  `assets/images/background/`, mas não `assets/images/letters/` (código
  morto, ok) nem arquivos individuais fora dessas pastas — se adicionar uma
  pasta de assets nova, lembre de declará-la aqui.
- **`README.md`** ainda é o boilerplate padrão do `flutter create`.
- **Nome do app:** `MaterialApp.title` em `main.dart` ainda é `'Fase 1 — Jogo
  da Memória'`, desatualizado desde que o app ganhou múltiplos jogos/fases.
  `android:label` no `AndroidManifest.xml` é `"linguagens"`.
