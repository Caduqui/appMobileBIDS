import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/fruit.dart';
import '../models/game_phase_status.dart';
import '../models/memory_card_model.dart';

class MemoryGameController extends ChangeNotifier {
  MemoryGameController({List<Fruit> fruits = kPhase1Fruits}) : _fruits = fruits;

  final List<Fruit> _fruits;

  List<MemoryCardModel> cards = [];
  GamePhaseStatus status = GamePhaseStatus.previewing;

  /// Chamado quando um par é confirmado como igual — a tela usa isso
  /// pra disparar o efeito de comemoração sem o controller conhecer a UI.
  VoidCallback? onMatchFound;

  String? _firstPickId;
  String? _secondPickId;

  static const _previewDuration = Duration(seconds: 4);
  static const _mismatchDuration = Duration(seconds: 1);
  static const _matchDuration = Duration(milliseconds: 500);

  void startPhase() {
    cards = _generateShuffledPairs();
    status = GamePhaseStatus.previewing;
    _firstPickId = null;
    _secondPickId = null;
    notifyListeners();

    Future.delayed(_previewDuration, () {
      cards = [
        for (final c in cards) c.copyWith(state: CardState.faceDown),
      ];
      status = GamePhaseStatus.waitingFirstPick;
      notifyListeners();
    });
  }

  List<MemoryCardModel> _generateShuffledPairs() {
    final pairs = <MemoryCardModel>[];
    for (final fruit in _fruits) {
      pairs.add(MemoryCardModel(cardId: '${fruit.id}_a', fruit: fruit, state: CardState.faceUp));
      pairs.add(MemoryCardModel(cardId: '${fruit.id}_b', fruit: fruit, state: CardState.faceUp));
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
    final firstId = _firstPickId!;
    final secondId = _secondPickId!;
    final first = _cardById(firstId);
    final second = _cardById(secondId);
    final isMatch = first.fruit.id == second.fruit.id;

    if (isMatch) {
      Future.delayed(_matchDuration, () {
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