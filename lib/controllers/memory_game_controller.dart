import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/game_phase_status.dart';
import '../models/memory_card_model.dart';
import '../models/word_item.dart';

class MemoryGameController extends ChangeNotifier {
  MemoryGameController({
    required this._items,
    this._previewDuration = const Duration(seconds: 4),
  });

  final List<WordItem> _items;
  final Duration _previewDuration;

  List<MemoryCardModel> cards = [];
  GamePhaseStatus status = GamePhaseStatus.previewing;

  /// Chamado quando um par é confirmado como igual — a tela usa isso
  /// pra disparar o efeito de comemoração sem o controller conhecer a UI.
  VoidCallback? onMatchFound;

  String? _firstPickId;
  String? _secondPickId;

  /// Os Future.delayed abaixo podem disparar depois que o jogador já saiu da
  /// tela; sem essa trava eles chamariam notifyListeners num controller
  /// descartado.
  bool _disposed = false;

  /// Incrementa a cada startPhase(): um preview de uma rodada antiga não pode
  /// virar as cartas de uma rodada nova (ex.: "Jogar novamente").
  int _round = 0;

  static const _mismatchDuration = Duration(seconds: 1);
  static const _matchDuration = Duration(milliseconds: 500);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void startPhase() {
    final round = ++_round;
    cards = _generateShuffledPairs();
    status = GamePhaseStatus.previewing;
    _firstPickId = null;
    _secondPickId = null;
    notifyListeners();

    Future.delayed(_previewDuration, () {
      if (_disposed || round != _round) return;
      cards = [
        for (final c in cards) c.copyWith(state: CardState.faceDown),
      ];
      status = GamePhaseStatus.waitingFirstPick;
      notifyListeners();
    });
  }

  List<MemoryCardModel> _generateShuffledPairs() {
    final pairs = <MemoryCardModel>[];
    for (final item in _items) {
      pairs.add(MemoryCardModel(cardId: '${item.id}_a', item: item, state: CardState.faceUp));
      pairs.add(MemoryCardModel(cardId: '${item.id}_b', item: item, state: CardState.faceUp));
    }
    pairs.shuffle(Random());
    return pairs;
  }

  void onCardTap(MemoryCardModel tappedCard) {
    final canTap = status == GamePhaseStatus.waitingFirstPick ||
        status == GamePhaseStatus.waitingSecondPick;
    if (!canTap) return;
    if (tappedCard.state != CardState.faceDown) return;

    _updateCard(tappedCard.cardId, CardState.faceUp);

    if (_firstPickId == null) {
      _firstPickId = tappedCard.cardId;
      status = GamePhaseStatus.waitingSecondPick;
      notifyListeners();
      return;
    }

    _secondPickId = tappedCard.cardId;
    status = GamePhaseStatus.checkingPair;
    notifyListeners();
    _resolvePair();
  }

  /// Substitui o card pela sua cópia com novo estado, em vez de mutar
  /// o objeto existente — mantém a lista imutável ponta a ponta.
  void _updateCard(String cardId, CardState newState) {
    cards = [
      for (final c in cards)
        c.cardId == cardId ? c.copyWith(state: newState) : c,
    ];
  }

  MemoryCardModel _cardById(String id) => cards.firstWhere((c) => c.cardId == id);

  void _resolvePair() {
    final round = _round;
    final firstId = _firstPickId!;
    final secondId = _secondPickId!;
    final first = _cardById(firstId);
    final second = _cardById(secondId);
    final isMatch = first.item.id == second.item.id;

    if (isMatch) {
      Future.delayed(_matchDuration, () {
        if (_disposed || round != _round) return;
        _updateCard(firstId, CardState.matched);
        _updateCard(secondId, CardState.matched);
        onMatchFound?.call();
        _finishResolution();
      });
    } else {
      _updateCard(firstId, CardState.mismatchError);
      _updateCard(secondId, CardState.mismatchError);
      notifyListeners();

      Future.delayed(_mismatchDuration, () {
        if (_disposed || round != _round) return;
        _updateCard(firstId, CardState.faceDown);
        _updateCard(secondId, CardState.faceDown);
        _finishResolution();
      });
    }
  }

  void _finishResolution() {
    _firstPickId = null;
    _secondPickId = null;

    final allMatched = cards.every((c) => c.state == CardState.matched);
    status = allMatched ? GamePhaseStatus.completed : GamePhaseStatus.waitingFirstPick;
    notifyListeners();
  }
}
