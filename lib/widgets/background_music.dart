import 'package:flutter/widgets.dart';

import '../audio/game_audio.dart';

/// Avisa o [BackgroundMusic] quando a tela dele volta a ficar por cima (o
/// jogador voltou de um jogo pro menu). Registrado no `MaterialApp`
/// (`navigatorObservers` em `main.dart`).
final RouteObserver<ModalRoute<void>> musicRouteObserver = RouteObserver();

/// Diz qual música toca enquanto esta tela está visível. Cada tela embrulha
/// o próprio conteúdo: as de menu com [MusicTrack.menu], as de jogo com
/// [MusicTrack.game]. Entre telas com a mesma faixa a música segue sem
/// cortar ([GameAudio.playMusic] ignora pedido da faixa que já toca).
class BackgroundMusic extends StatefulWidget {
  final MusicTrack track;
  final Widget child;

  const BackgroundMusic({super.key, required this.track, required this.child});

  @override
  State<BackgroundMusic> createState() => _BackgroundMusicState();
}

class _BackgroundMusicState extends State<BackgroundMusic> with RouteAware {
  ModalRoute<void>? _route;

  @override
  void initState() {
    super.initState();
    GameAudio.instance.playMusic(widget.track);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      if (_route != null) musicRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) musicRouteObserver.subscribe(this, route);
    }
  }

  /// A tela de cima saiu (ex.: voltou do jogo pro menu de fases): retoma a
  /// música desta tela.
  @override
  void didPopNext() => GameAudio.instance.playMusic(widget.track);

  @override
  void dispose() {
    musicRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
