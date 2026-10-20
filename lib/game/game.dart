import 'dart:math';

import 'board.dart';
import 'pieces.dart';

enum GameMode { classic, daily }

/// Outcome of one placement, for scoring feedback and effects.
class Move {
  const Move({required this.clear, required this.points, required this.combo, this.perfect = false});

  final Clear clear;
  final int points;

  /// The move emptied the whole board.
  final bool perfect;

  /// Combo level after this move (0 = no active combo).
  final int combo;
}

/// One game: board, the 3-piece tray, score and combo.
///
/// Daily games deal from a date-seeded sequence that ignores the board, so every
/// player gets the same pieces in the same order and scores are comparable.
/// Classic games deal sets where at least one piece fits, which keeps runs long.
class Game {
  Game.classic({Random? random})
      : mode = GameMode.classic,
        dailyNumber = null,
        _rng = random ?? Random() {
    _deal();
  }

  Game.daily(this.dailyNumber)
      : mode = GameMode.daily,
        _rng = Random(dailyNumber! * 7919 + 17) {
    _deal();
  }

  final GameMode mode;
  final int? dailyNumber;
  final Random _rng;
  final board = Board();
  final List<Piece?> tray = List.filled(3, null);

  int score = 0;
  int combo = 0;
  int bestCombo = 0;
  int linesCleared = 0;
  int _movesSinceClear = 0;
  bool revived = false;

  /// Number of 3-piece sets dealt; lets a saved daily game replay its piece sequence.
  int _deals = 0;

  /// A combo survives this many placements without a clear.
  static const comboGrace = 3;

  bool get isOver => tray.every((p) => p == null || !board.canPlaceAnywhere(p));

  bool canPlace(int slot, int row, int col) {
    final p = tray[slot];
    return p != null && board.canPlace(p, row, col);
  }

  Move place(int slot, int row, int col) {
    final p = tray[slot]!;
    assert(board.canPlace(p, row, col));
    final clear = board.place(p, row, col);
    tray[slot] = null;

    var points = p.size;
    final perfect = !clear.isEmpty && board.isEmpty;
    if (clear.isEmpty) {
      if (++_movesSinceClear >= comboGrace) combo = 0;
    } else {
      combo++;
      _movesSinceClear = 0;
      linesCleared += clear.lines;
      // 10 per line, more for clearing several at once, multiplied by the combo.
      points += 10 * clear.lines * clear.lines * combo;
      if (perfect) points += 300;
    }
    score += points;
    bestCombo = max(bestCombo, combo);

    if (tray.every((p) => p == null)) _deal();
    return Move(clear: clear, points: points, combo: combo, perfect: perfect);
  }

  /// Second chance after game over (rewarded ad): a fresh set of pieces that all fit.
  void revive() {
    revived = true;
    final fitting = allPieces.where(board.canPlaceAnywhere).toList()..sort((a, b) => a.size - b.size);
    for (var i = 0; i < tray.length; i++) {
      tray[i] = fitting.isEmpty ? null : fitting[min(i, fitting.length - 1)];
    }
  }

  void _deal() {
    _deals++;
    if (mode == GameMode.daily) {
      for (var i = 0; i < tray.length; i++) {
        tray[i] = randomPiece(_rng);
      }
      return;
    }
    for (var attempt = 0; attempt < 20; attempt++) {
      for (var i = 0; i < tray.length; i++) {
        tray[i] = randomPiece(_rng);
      }
      if (tray.any((p) => board.canPlaceAnywhere(p!))) return;
    }
  }
}

// ---- saving a game in progress ----

extension GameSave on Game {
  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'daily': dailyNumber,
        'cells': board.cells,
        'tray': [for (final p in tray) p?.id],
        'score': score,
        'combo': combo,
        'bestCombo': bestCombo,
        'lines': linesCleared,
        'sinceClear': _movesSinceClear,
        'revived': revived,
        'deals': _deals,
      };
}

Game gameFromJson(Map<String, dynamic> json, {Random? random}) {
  final Game g;
  if (json['mode'] == GameMode.daily.name) {
    g = Game.daily(json['daily'] as int);
    // Advance the seeded sequence to where the saved game was.
    while (g._deals < (json['deals'] as int)) {
      g._deal();
    }
  } else {
    g = Game.classic(random: random);
  }
  g.board.cells.setAll(0, List<int>.from(json['cells'] as List));
  final tray = List<String?>.from(json['tray'] as List);
  for (var i = 0; i < g.tray.length; i++) {
    g.tray[i] = tray[i] == null ? null : piecesById[tray[i]];
  }
  g
    ..score = json['score'] as int
    ..combo = json['combo'] as int
    ..bestCombo = json['bestCombo'] as int
    ..linesCleared = json['lines'] as int
    .._movesSinceClear = json['sinceClear'] as int
    ..revived = json['revived'] as bool;
  return g;
}

/// Daily puzzle number: days since launch day, starting at 1.
int dailyNumberFor(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(2026, 10, 20)).inDays + 1;
