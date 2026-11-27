# AGENTS.md

Guia para agentes de IA (e humanos) trabalhando neste repositório. Leia isto
antes de mexer no código.

## O que é o projeto

App Flutter infantil para ensinar português a crianças. Hoje tem:

- **Lobby** (`HomeScreen`) → **Escolha do jogo** (`MinigamesScreen`) →
  **Escolha de dificuldade** (`DifficultyScreen`) → **Escolha de fase**
  (`PhasesScreen`) → **Jogo**. O Sons das Letras é a exceção: do card vai
  direto pra **Escolha de letra** (`LetterPickerScreen`, A–Z) → **Jogo**.
- Dois minigames implementados: **Jogo da Memória** e **Complete a Palavra**.
  Cada um tem 3 dificuldades (Fácil/Médio/Difícil), com 8 fases no Fácil e no
  Médio e 7 no Difícil (ver `_expectedPhaseCounts` em
  `test/game_data_test.dart`), cobrindo temas como frutas, animais, objetos
  escolares, brinquedos, transportes, comidas, higiene e emoções. O nº de
  fases não precisa ser igual entre dificuldades — o Difícil tem 1 fase a
  menos porque "Transportes" só existe lá uma vez (não duplicamos tema dentro
  da mesma dificuldade).
- Terceiro minigame: **Sons das Letras**. Uma letra por fase, de A a Z,
  **sem dificuldade**: o menu é uma tela só com as 26 letras e "Próxima
  letra" percorre o alfabeto inteiro. (Antes era dividido em Fácil A–I,
  Médio J–R, Difícil S–Z, e o usuário mudou de ideia: não faz sentido o
  alfabeto ter dificuldade. Não volte pros blocos.) A letra grande de um lado
  e, ao lado, a **"boquinha"** (termo da fonoaudiologia, Método das
  Boquinhas) fazendo o som da letra ("mmm", "fff" — o som, não o nome
  "eme", "efe"), mais **2 ou 3 palavras de exemplo** que têm a letra (no
  começo, meio ou fim, como nos slides do método). A
  boquinha é uma foto real de boca, animada em código, com o áudio do som tocando
  junto; ver "Boquinhas e áudios" abaixo.
- Som em todo o app: **efeitos** (toque em botão/card, virar carta,
  encaixar letra, acerto, erro, vitória) e **música de fundo** em loop, uma
  nos menus e outra nos jogos, que some durante as falas do Sons das Letras.
  Ver "Sons e música de fundo" abaixo.
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
flutter test           # roda toda a suíte (~350 testes, ~20s)
flutter run             # roda em device/emulador conectado
flutter build apk --release   # gera o APK para instalar manualmente
dart run tool/gen_audio_envelopes.dart   # após trocar/adicionar um .mp3 (precisa do ffmpeg)
dart run tool/gen_azure_voice.dart <pasta> [nomes...]   # gera áudio com a voz Yara (ver "Boquinhas e áudios")
bash tool/treat_sound.sh sfx|music <entrada> <saída>   # trata efeito/música antes de ir pro app (ver "Sons e música de fundo")
```

O Flutter deste ambiente é o 3.44.9 (stable), instalado em
`~/Downloads/flutter_windows_3.44.9-stable`(ou já no PATH). Rode `flutter
doctor` se algo parecer errado com o toolchain. O app usa plugin nativo
(`video_player` e `audioplayers`), e no Windows o Flutter só compila app com plugin se o
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
audio/         — efeitos e música de fundo (GameAudio). Telas e widgets usam.
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
- `letter_phases.dart` — `kLetterPhases`: `List<LetterPhase>` única, de A
  a Z (sem `Difficulty`), uma `LetterPhase` por letra, com a
  pose da boca (`mouth`, e `release` nos sons que estouram), 2–3 `words` do
  `word_catalog.dart` e os caminhos derivados da letra (`audioPath`,
  `videoPath`). As poses ficam em constantes no topo do arquivo (`_a`,
  `_lipsClosed`, `_teethOnLip`...) e são compartilhadas por letras com a
  mesma articulação (P/B, F/V, S/Z, C/G/K/Q).
- `audio_envelopes.dart` — **gerado** por `tool/gen_audio_envelopes.dart`,
  não edite à mão: o volume (0–100) de cada `.mp3` de `assets/audio/` a cada
  10 ms. É o que sincroniza a boca com o som (ver "Boquinhas e áudios").
- `lip_sync.dart` — `letterTrack(phase)` e `wordTrack(word)`: transformam o
  volume do áudio numa `MouthTrack` (uma pose a cada 10 ms). `wordPoses()`
  converte a grafia em sons com as regras de leitura do português ("qu",
  "ch", "lh", "nh", "ç", "rr", "ss", "l"/"e"/"o" finais...).

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
- `lip_sync_player.dart` — `LipSyncPlayer`: toca uma `MouthTrack` junto com
  o áudio e expõe a `pose` a cada quadro. Não é regra de jogo, mas mora aqui
  por ser um `ChangeNotifier` sem widgets. A boca anda num `Ticker` próprio
  (suave) e o relógio é corrigido pela posição real do `VideoPlayerController`,
  que o plugin só atualiza a cada 100 ms — seguir a posição direto deixaria
  a boca aos trancos. O atraso do aparelho entre `play()` e o som sair é
  aprendido a cada toque (`_latency`, static).
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
  A arte de cada card é a `MinigameArt` (ver `widgets/`), desenhada em
  código, em retrato 3:4; o título fica embaixo, em texto do Flutter (não
  dentro da arte). Largura do card e fonte do título escalam em tablet via
  `responsiveValue`; o arredondamento do card é 10% da largura, o mesmo que
  a arte usa no próprio desenho.
- `difficulty_screen.dart` e `phases_screen.dart` — genéricas, servem pra
  qualquer minigame. Recebem `gameTitle`, `phaseTitlesFor` (função
  `Difficulty → List<String>`) e `gameBuilder` (função `(Difficulty, int) →
  Widget`) de quem as chama. **Um minigame novo não deveria precisar de telas
  de dificuldade/fase próprias** — só instanciar `DifficultyScreen` com os
  parâmetros certos, como `minigames_screen.dart` já faz pra Memória e o
  Complete a Palavra. Botões/cards escalam em tablet (`responsiveValue`).
  Só um jogo sem níveis (como o Sons das Letras) tem menu próprio.
- `letter_picker_screen.dart` — `LetterPickerScreen`, o menu do Sons das
  Letras: as 26 letras ("Aa", "Bb"...) num `Wrap` centralizado. O tamanho
  dos botões é calculado (`_fittingTileSize`, dentro de um `LayoutBuilder`)
  pra o alfabeto inteiro caber na tela sem rolar em qualquer dispositivo e
  orientação — criança pequena não sabe rolar —, com teto por
  `responsiveValue` e um mínimo que, numa tela minúscula, deixa rolar.
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
  duplique entre os dois layouts. **Retorno da letra (pedido do usuário):**
  letra certa → a voz Yara fala o **nome** da letra ("eme", não o som
  "mmm"); letra errada → só aquela peça da bandeja fica vermelha e treme na
  horizontal (`_wrongTileId` + um `ShakeWidget` por peça, contador em
  `_shakeKeys`) com o som de erro "tã-tã"; palavra completa → a voz fala a
  palavra, depois uma comemoração sorteada ("Parabéns!", "Muito bem!", "Isso
  aí!") e só então a vinheta de vitória (`_celebrate`). A última letra não
  fala o nome, vai direto pra palavra. "Próxima palavra", "Jogar novamente"
  e sair da tela cortam a fala em andamento (`GameAudio.stopVoice`). O
  controller só avisa acerto/erro; qual peça foi tocada a tela guarda em
  `_tappedTile`.
- `letter_sounds_screen.dart` — tela do Sons das Letras. Recebe só
  `phaseIndex` (posição em `kLetterPhases`, 0 = A) e "Próxima letra" faz
  `pushReplacement` pra `phaseIndex + 1` até o Z. Sem dificuldade, a cor é
  uma só, `kLetterSoundsColor` (roxo do card do jogo). **Sem controller em
  `controllers/`** de jogo: não há regra, só tocar som e mexer a boca. A
  boquinha é o `LipSyncPlayer` tocando `letterTrack`/`wordTrack`, desenhada
  por `MouthView` (foto deformada) — **a boca fala junto tanto o som da
  letra quanto as palavras**. O som é um `VideoPlayerController` do plugin
  `video_player` (que toca áudio puro também; os efeitos e a música de
  fundo é que usam o `audioplayers`, ver "Sons e música de fundo"). A
  música de fundo some enquanto a fala toca (`_updateDuck`, que olha o
  `LipSyncPlayer.isPlaying` e, no modo vídeo, o próprio vídeo). Os áudios das palavras são abertos já ao entrar na tela
  (abrindo só no toque, o som saía atrasado). Tudo que é mídia é conferido
  no `AssetManifest` antes de abrir: letra sem áudio anima em silêncio,
  palavra sem áudio não faz nada ao toque. Se existir `assets/videos/letters/<letra>
  .mp4`, o vídeo gravado substitui a boquinha animada (falha ao abrir
  mostra "Não foi possível tocar o vídeo"). Letra e boca ficam sempre lado a
  lado em quadrados (`Center` + `AspectRatio(1)`); as palavras vão embaixo
  em retrato e numa terceira coluna em paisagem. Toca sozinho 700ms depois
  de abrir (fim da transição de tela) e de novo, do começo, a cada toque na
  letra, na boca ou em "Ouvir de novo".

### widgets/

- `memory_card_widget.dart` — flip 3D (`Transform`+`rotateY`) com shake em
  erro. Frente mostra `WordImage` + nome (em `FittedBox` pra nomes longos tipo
  "Helicóptero" não estourarem a largura do card). O verso é o
  `MemoryCardBack` (`memory_card_back.dart`): a capivara mascote num medalhão
  branco sobre o azul do card da memória, desenhada em código e medida pelo
  lado menor da carta, porque a proporção da carta muda com a grade.
- `celebration_overlay.dart` / `shake_widget.dart` — mesmo padrão:
  `triggerKey` é um `int` incremental (não um `bool`), porque um bool não
  dispara a animação de novo se o valor continuar `true` entre dois acertos
  seguidos.
- `word_image.dart` — `WordImage`: desenha `item.imagePath` se existir, senão
  o `item.emoji` em `FittedBox`. É o único lugar que decide PNG-vs-emoji —
  outras telas nunca devem checar `imagePath`/`emoji` diretamente.
- `minigame_art.dart` — `MinigameArt`: arte dos cards da escolha de jogo,
  desenhada em código num quadro de 300x400 e escalada. Um mascote só, uma
  **capivara** com uma mexerica na cabeça (`capybara_drawing.dart`,
  `CapybaraDrawing`), atrás de um balcão de madeira mexendo nos objetos de
  cada jogo: cartas na Memória, letra na boca pra encaixar em G _ T O no
  Complete a Palavra, cantando com balão "A" nos Sons. Fundo chapado clarinho
  e borda na cor do jogo (azul, verde, roxo). O estilo veio de uma imagem de
  exemplo que o usuário mandou: desenho chapado com contorno marrom,
  capivara de perfil com focinho comprido, olho fechadinho feliz. Foi a
  terceira tentativa, e as duas anteriores foram rejeitadas: capivara em pé
  em 3D suave num fundo de degradê azul ("básica", "fundo genérico"), e
  depois uma com olhos grandes de íris, cílios e dentes, que ele achou
  **assustadora**. Não volte pra nenhuma das duas. Pra ver uma mudança,
  renderize a tela num PNG (`testWidgets` temporário +
  `RepaintBoundary.toImage`, carregando a Roboto do SDK com
  `FontLoader('Roboto')`, senão as letras saem como quadrados).
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
  arquivo. Arte desenhada em código segue a mesma ideia: um `AspectRatio`
  fixo dentro do próprio widget (ver `MinigameArt.aspectRatio`).
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
lábio, e a língua: ponta, dorso da frente, fundo e ponta fina — tudo 0–1,
interpolável) +
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

**Língua.** O usuário pediu a língua no mesmo nível de realismo da foto, e
a primeira (uma forma chapada com degradê) não estava. Hoje ela é uma
superfície 3D simples (`_paintTongue`): o corte do meio da língua, do
assoalho da boca por baixo até a ponta e daí até a raiz, é uma curva por 6
pontos que a pose move, abaulada nas bordas e com o sulco no meio; a malha
é projetada com perspectiva e iluminada ponto a ponto (luz "enrolada" de
tecido mole, brilho úmido, sombra do fundo da boca e dos dentes), com uma
textura gerada em código (`_tongueTexture`: papilas no dorso; lado de
baixo liso, com veias e o freio). Por isso a mesma malha mostra o dorso
deitado ("A"), a ponta subindo e mostrando o lado de baixo ("L", "T"), o
dorso da frente no palato ("I", "LH", "NH") e o fundo no véu ("C", "G").
As bordas vão pra cor do degradê do fundo da boca naquele ponto (não pro
preto), senão viram manchas mais escuras que a boca. As posições de cada
som seguem a fonética articulatória do português do Brasil: T/D/N/L e o
"r" fraco com a ponta nos alvéolos (o "L" com a ponta fina e os lados
baixos), LH/NH com o dorso no palato duro e a ponta embaixo, C/G/K/Q e o
"r" forte com o fundo no véu, S com a ponta perto dos alvéolos, X/J um
pouco mais atrás, e as vogais pela altura e anterioridade. Na palavra,
nos sons de lábio (P/B/M/F/V) a língua já vai pra vogal seguinte.

**Dentes.** Pelo mesmo motivo (retângulos com degradê pareciam "teclas"),
cada dente é uma malhinha 3D (`_paintTeeth`) com medidas reais em mm
(`_upperTeeth`/`_lowerTeeth`, `_mm` = 28 px): incisivo central largo,
lateral menor e mais curto, canino e pré-molares com ponta, numa arcada
em parábola (`_arch`) — os de trás recuam e escurecem. Luz ponto a ponto
com a mesma câmera da língua; o brilho do esmalte usa uma normal que gira
mais de lado a lado (sai uma faixinha vertical; com a normal da luz
difusa saía uma faixa horizontal de metal). Borda translúcida azulada,
colo amarelado, textura de esmalte (`_enamelTexture`) e sombra estreita
do lábio (larga deixava o pedaço visível todo cinza). Os de baixo ficam
2,5 mm atrás e 2,5 mm acima da borda dos de cima (sobremordida), e a
borda dos de cima fica 1,5 mm abaixo da linha dos lábios — senão no
sorriso ("I", "S") apareciam mais os de baixo. Os dentes se encostam
(fresta mostra o preto da boca) e há gengiva atrás perto do colo.

**Sincronia boca ↔ som.** A boca não anda num tempo fixo: é guiada pelo
volume real de cada áudio (`data/audio_envelopes.dart`, gerado com o
ffmpeg). Na letra, a boca chega na pose ~200 ms antes do som (320 ms nos
que estouram), segura enquanto o som dura e fecha quando ele acaba; nos
sons que estouram fica fechada até o estouro, inclusive durante o "mmm"
grave que vem antes do B/D/G. Na palavra, cada som vira uma
pose e as vogais são alinhadas aos picos de volume (as sílabas); se o nº de
picos não bater com o de sílabas, espalha os sons por igual. Pra mudar o
ritmo, mexa em `data/lip_sync.dart`; pra ver o resultado, renderize uma
tira de quadros de `track.poseAt(...)` (como o PNG das poses).

**Áudios.** Um arquivo por letra em `assets/audio/letters/` (`a.mp3` ...
`z.mp3`, o **som** da letra) e um por palavra de exemplo em
`assets/audio/words/` (`<id da palavra>.mp3`, ex. `abelha.mp3`). As pastas
já estão no `pubspec.yaml`; o teste de dados falha se aparecer arquivo com
nome fora da convenção, e `lip_sync_test.dart` falha se um áudio não tiver
curva de volume (rode o gerador). K e Q reusam o áudio do C, Y o do I, W o
do U; H não tem áudio.

**Todos os áudios (letras e palavras) são da voz feminina pt-BR
`pt-BR-YaraNeural` da Azure**, escolhida pelo usuário, gerados uma vez por
`tool/gen_azure_voice.dart` e gravados no app (o app não fala com a Azure
nem usa TTS ao vivo). O som de cada letra é pedido em IPA (`<phoneme>`), sem
vogal depois: "mmm", não "eme". O espectrograma confirmou que vem o som
certo (zumbido no M, chiado no S, estouro no P), mas curto (~0,3 s mesmo a
50% de velocidade), por isso `tool/treat_audio.sh` alonga os sons segurados
sem mudar o tom. B/D/G já vêm com o vozeamento antes do estouro. P/T/C são
só o estouro (0,1–0,23 s): pedir aspirado (`pʰ`) não muda nada. O usuário
pediu fala **devagar, pra criança entender**: palavras a -40% de velocidade
e letras alongadas pra ~1–1,5 s. Não acelere sem ele pedir. A boca segue o
áudio, então fica lenta junto. Em IPA o G
precisa ser o `g` comum: o `ɡ` (U+0261) volta um arquivo vazio.

Pra refazer ou adicionar um áudio: defina `AZURE_SPEECH_KEY`/
`AZURE_SPEECH_REGION` (recurso "Speech" do usuário, nível gratuito F0,
500 mil caracteres/mês; o app inteiro gasta ~3 mil), rode `dart run
tool/gen_azure_voice.dart <pasta> [nomes...]`, trate cada `.wav` com `bash
tool/treat_audio.sh <wav> <mp3> [duração]` (as durações por letra estão no
cabeçalho do script), copie pra `assets/audio/` e rode o gerador de curvas.
Nunca escreva a chave em arquivo do repositório. Se a pronúncia de uma
palavra sair errada, ponha a grafia falada em `_spoken` no gerador.

Histórico das vozes: os primeiros áudios eram recortes da série "Os sons das
letras com boquinhas" (Método das Boquinhas, Renata Jardini, com permissão
só pros áudios; as palavras de exemplo vêm dos slides de lá), e as 15
palavras de H/K/Q/W/Y que não existiam lá foram feitas com "Microsoft Maria"
do Windows e depois com `pf_dora` do Kokoro, ambas rejeitadas pelo usuário.
Ele pediu a voz da narradora, mas **não clonamos a voz de uma pessoa real**
sem o consentimento dela; entre as vozes femininas pt-BR com uso permitido,
a Yara era a de tom mais parecido (~211 Hz, igual à narradora), e o usuário
preferiu trocar tudo por ela pra ter uma voz só no app. As gravações
originais não estão mais no app.

**Tratamento dos áudios (`tool/treat_audio.sh`).** Corta o silêncio do
começo/fim (o áudio da letra deve começar já no som: silêncio no início
atrasa o som em relação à boca), alonga até a duração alvo quando há uma,
leva o volume médio a ~-14 dB com limitador pra não distorcer e grava mp3
mono 44,1 kHz 96 kbps. Confira o resultado pelo espectrograma
(`showspectrumpic` do ffmpeg, sem `drawtext`, que trava) — não dá pra ouvir
daqui.

**Vídeo gravado (opcional).** `assets/videos/letters/<letra>.mp4` (H.264 +
AAC, só a boca, de frente, 1–2s) substitui a boquinha animada daquela
letra, com o som da própria gravação.

Histórico: uma primeira tentativa de boca desenhada + TTS foi descartada (o
TTS do aparelho não produz o som isolado das letras e erra sílabas soltas;
a boca não representava a fonética). Depois veio uma boca toda desenhada em
código com áudio gravado, também descartada por parecer desenho; a atual
(foto real deformada) foi escolha do usuário. Não volte pro TTS ao vivo do
aparelho nem pra boca 100% desenhada. Os áudios gerados uma vez com a Yara e
gravados no app são outra coisa, e ficam.

## Sons e música de fundo

`lib/audio/game_audio.dart` tem a regra: `Sfx` (efeitos) e `MusicTrack`
(músicas) como enums com o caminho do arquivo, e o `GameAudio.instance`,
um só pro app inteiro porque a música atravessa as telas. Quem toca de fato
é um `AudioBackend`: o padrão é o `SilentAudioBackend` (mudo), e só o
`main()` liga o `AudioplayersBackend` (`audioplayers_backend.dart`). Por
isso os testes, que montam as telas sem passar pelo `main()`, rodam mudos e
sem plugin nativo, e a regra é testada com um backend falso
(`test/game_audio_test.dart`). Toda falha de áudio vira só um `debugPrint`:
som nunca pode travar a navegação.

- **Efeitos:** `GameAudio.instance.play(Sfx.tap)`. Os botões/cards de
  navegação tocam `tap` dentro do próprio widget privado (`_HomeButton`,
  `_MinigameCard`, `_DifficultyButton`, `_PhaseCard`, `_LetterTile`, os
  `_FooterButton` dos jogos), não em cada `onTap` de quem chama. Nos jogos
  os controllers avisam por callback (`onCardFlipped`, `onMismatch`,
  `onMatchFound` na memória; `onLetterPlaced`, `onWrongLetter`,
  `onWordSolved` no Complete a Palavra) e a tela toca o som; o último par
  da memória toca só `win`, não `correct` junto. No Sons das Letras
  não há som de toque na letra, na boca nem nas palavras: o toque já toca
  a fala.
- **Falas (Complete a Palavra):** `GameAudio.say([clipes])` fala em
  sequência num player próprio do `audioplayers` (não o `video_player` do
  Sons das Letras, que precisa da posição pra boca; aqui não há boca), com a
  música abaixada do começo ao fim, e devolve `false` se outra fala ou
  `stopVoice()` cortou — quem chamou não continua (ex.: não toca a vinheta
  de uma palavra que a criança já pulou). Os caminhos ficam em
  `audio/voice_clips.dart` (`letterNameClip`, `wordClip`, `cheerClips`), e a
  tela pré-carrega as falas da fase ao abrir (`GameAudio.preload`), senão o
  nome da letra sairia atrasado no primeiro toque.
- **Música:** cada tela embrulha o `Scaffold` em
  `BackgroundMusic(track: ...)` (`widgets/background_music.dart`): menus
  (lobby, escolha de jogo, dificuldade, fase, letra) com `MusicTrack.menu`,
  jogos com `MusicTrack.game`. Pedir a faixa que já toca não faz nada, então
  ela segue sem cortar entre telas do mesmo contexto; ao voltar de um jogo, o
  `RouteObserver` (`musicRouteObserver`, registrado no `MaterialApp`) avisa
  a tela de baixo (`didPopNext`) e ela pede a faixa dela de novo. App em
  segundo plano pausa a música (`AppLifecycleListener` no `GameAudio`).
  **Tela nova: embrulhe em `BackgroundMusic`**, senão ela fica com a música
  da tela anterior.
- **Abaixar durante a fala:** `GameAudio.setDucked(true)` zera a música na
  hora; `setDucked(false)` devolve depois de 600 ms (a criança costuma tocar
  de novo logo em seguida, e a música não fica subindo e descendo).
  `now: true` ao sair da tela, pra não deixar timer pendurado.
- **Volumes:** os arquivos são normalizados por `tool/treat_sound.sh`
  (efeitos com média -18 dB em WAV mono, músicas com média -20 dB em mp3
  estéreo, só ganho constante pro loop não ganhar degrau). O volume do
  player fica em `MusicTrack.volume` (menu 0,5; jogo 0,3, uns 16 dB abaixo
  das falas) e `GameAudio.sfxVolume` (0,6).
- **Por que o plugin `audioplayers`** (escolhido pelo usuário) além do
  `video_player`: o `video_player` abre um player pesado por arquivo e
  demora pra começar, então o clique sairia atrasado. Os efeitos ficam
  pré-carregados em modo de baixa latência (SoundPool no Android), dois
  players por efeito. O contexto de áudio é `mixWithOthers` (no Android,
  sem pedir foco de áudio): senão o `video_player` perderia o foco e
  pausaria a fala da letra quando um efeito tocasse.
- **Pastas:** `assets/sfx/`, `assets/music/` e `assets/voice/`
  (`letter_names/<letra>.mp3`, `words/<id da palavra>.mp3`,
  `cheers/<id>.mp3`), **fora de `assets/audio/`** de propósito, porque lá
  todo `.mp3` precisa de curva de volume pra boca (`lip_sync_test`) e a
  lista de palavras tem que ser exatamente a do Sons das Letras
  (`game_data_test`). As falas de `assets/voice/` saem do mesmo
  `tool/gen_azure_voice.dart` (`dart run tool/gen_azure_voice.dart <saída>
  voice` gera só elas) e são tratadas com `tool/treat_audio.sh` sem duração
  alvo, como as palavras do Sons das Letras. Pra trocar um som: trate com `bash tool/treat_sound.sh
  sfx|music <entrada> <saída>` (ffmpeg fora do PATH: `FFMPEG=<caminho do
  ffmpeg.exe>`) e grave por cima com o mesmo nome. Não dá pra ouvir daqui:
  os efeitos foram escolhidos pelo nome, pela duração e pela melodia
  (subindo = alegre), e vale o usuário ouvir no aparelho.

**Origem e licença** (todos CC0, domínio público: uso livre em app, sem
crédito obrigatório; por isso não há tela de créditos):

| Arquivo | Origem | Autor | Licença |
|---|---|---|---|
| `music/menu.mp3` | "Children's March Theme" (1:04, loop), opengameart.org/content/childrens-march-theme | CleytonKauffman | CC0 |
| `music/game.mp3` | "Children's Game Music 4 - Activity" (0:52; o autor não diz que emenda em loop, o fim é um pouco mais baixo que o começo), opengameart.org/content/childrens-game-music-4-activity | heartade | CC0 |
| `sfx/tap.wav` | `select_001.ogg` do pacote Interface Sounds, kenney.nl/assets/interface-sounds | Kenney | CC0 |
| `sfx/flip.wav` | `drop_002.ogg` (Interface Sounds) | Kenney | CC0 |
| `sfx/place.wav` | `pluck_002.ogg` (Interface Sounds) | Kenney | CC0 |
| `sfx/correct.wav` | `confirmation_001.ogg` (Interface Sounds) | Kenney | CC0 |
| `sfx/wrong.wav` | `jingles_SAX09.ogg` (Music Jingles): duas notas descendo no sax, o "tã-tã" de erro que o usuário pediu (o som famoso de TV tem direitos autorais) | Kenney | CC0 |
| `sfx/win.wav` | `jingles_STEEL10.ogg` do pacote Music Jingles, kenney.nl/assets/music-jingles | Kenney | CC0 |

Outras opções que o usuário viu e não escolheu (todas CC0 no OpenGameArt):
"Children's Game Music 1 - Picnic" e "3 - Home" (heartade), "Happy Clappy
Loop" (OwlishMedia), "Flowerbed Fields" (Zane Little Music), "Ukulele
Forest" (StarNinjas). Kevin MacLeod (incompetech.com) é CC-BY 4.0: daria pra
usar, mas exigiria uma tela de créditos no app.

## Testes

Cinco arquivos em `test/`, todos relevantes — não pule a suíte:

- `game_audio_test.dart` — regra do `GameAudio` com um backend falso: a
  mesma música não reinicia entre telas, a fala abaixa a música na hora e
  ela volta depois do atraso (e não sobe entre dois toques seguidos), app em
  segundo plano pausa, falha do áudio não vira exceção, falas em sequência
  (e a cortada não continua), e todo arquivo de `Sfx`/`MusicTrack` existe e
  fica fora de `assets/audio/`. Também confere que existe a fala do nome de
  cada letra, de cada palavra do Complete a Palavra e das comemorações:
  **palavra nova numa fase do Complete a Palavra precisa da fala** (rode
  `dart run tool/gen_azure_voice.dart <saída> voice/words/<id>`).

- `lip_sync_test.dart` — toda curva de volume existe e corresponde a um
  `.mp3` (gerador em dia), toda palavra tem áudio, trilhas de letra e
  palavra começam/terminam em repouso, som segurado fica na pose da letra,
  som que estoura fecha antes e solta depois, regras de leitura de
  `wordPoses` ("qu", "lh", "ç", "rr", "l"/"e"/"o" finais).

- `game_data_test.dart` — valida os **dados**: cada dificuldade tem o nº de
  fases esperado (`_expectedPhaseCounts`, hoje 8/8/7), nº certo de itens por
  fase, ids únicos, PNGs referenciados existem de fato no disco, palavras do
  Complete a Palavra comportam as lacunas da dificuldade, alfabeto do Sons
  das Letras completo e em ordem (A–Z, lista única), 2–3 palavras com a letra, áudio de toda
  letra menos o H, nomes de vídeo e áudio
  na convenção. **Qualquer fase
  nova precisa passar aqui — e se mudar a contagem de fases de alguma
  dificuldade, atualize `_expectedPhaseCounts`.**
- `completion_controller_test.dart` — testa `CompletionGameController`
  isolado (sem widgets), incluindo `Random` fixo pra determinismo, regra de
  acento nunca sumir, letra errada não preenche, avançar de palavra/fase.
- `widget_test.dart` — fluxo de navegação ponta a ponta e testes de layout
  (centralização, proporção de imagem, sem overflow). Roda **todas as fases
  dos três jogos, e o menu de letras A–Z, em 4 combinações de dispositivo** (`_useDevice` +
  `_devicePortraitPhone`/`_deviceLandscapePhone`/`_devicePortraitTablet`/
  `_deviceLandscapeTablet`, todas a `devicePixelRatio: 3.0`) só pra pegar
  overflow — é a rede de segurança contra nome/palavra comprida ou grid
  invertido estourando o layout em alguma combinação de tela. **Qualquer tela
  nova, ou mudança de layout numa existente, devia entrar nesse loop** (ou
  ganhar um teste equivalente) em vez de só ser testada em celular retrato.
  Tem também testes específicos do swap de colunas/linhas do grid da memória
  (`grid da memória inverte/mantém...`) e do layout lado a lado do lobby em
  paisagem, e de que o menu de letras mostra as 26 dentro da tela e o
  "Próxima letra" passa do I pro J e some no Z, e de que no Complete a
  Palavra a letra errada fica vermelha, treme e depois volta ao normal. Testes de tela do Sons das Letras chamam `_letVideoLoad(tester)`
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
- **`pubspec.yaml` `assets:`** lista `assets/fruits/`, `assets/images/mouth/`,
  `assets/images/background/`, as pastas de áudio/vídeo e `assets/sfx/` +
  `assets/music/`, mas não `assets/images/letters/` (código
  morto, ok) nem arquivos individuais fora dessas pastas — se adicionar uma
  pasta de assets nova, lembre de declará-la aqui.
- **`README.md`** ainda é o boilerplate padrão do `flutter create`.
- **Nome do app:** `MaterialApp.title` em `main.dart` ainda é `'Fase 1 — Jogo
  da Memória'`, desatualizado desde que o app ganhou múltiplos jogos/fases.
  `android:label` no `AndroidManifest.xml` é `"linguagens"`.
