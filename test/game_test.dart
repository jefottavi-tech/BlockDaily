import 'dart:math';

import 'package:block_daily/game/board.dart';
import 'package:block_daily/game/game.dart';
import 'package:block_daily/game/pieces.dart';
import 'package:flutter_test/flutter_test.dart';

Piece p(String id) => piecesById[id]!;

void fillRow(Board b, int r, {int except = -1}) {
  for (var c = 0; c < Board.size; c++) {
    if (c != except) b.cells[r * Board.size + c] = 1;
  }
}

void main() {
  group('pieces', () {
    test('every piece is well formed and ids are unique', () {
      expect(piecesById.length, allPieces.length);
      for (final piece in allPieces) {
        expect(piece.cells.toSet().length, piece.size, reason: piece.id);
        expect(piece.cells.any((c) => c.r == 0), isTrue, reason: '${piece.id} starts at row 0');
        expect(piece.cells.any((c) => c.c == 0), isTrue, reason: '${piece.id} starts at col 0');
        expect(piece.rows, lessThanOrEqualTo(5));
      }
      expect(p('l5a').size, 5);
      expect(p('o3').rows, 3);
    });

    test('random dealing follows weights roughly', () {
      final rng = Random(1);
      final counts = <String, int>{};
      for (var i = 0; i < 20000; i++) {
        counts.update(randomPiece(rng).id, (n) => n + 1, ifAbsent: () => 1);
      }
      expect(counts.keys, hasLength(allPieces.length));
      expect(counts['dot']! / counts['o3']!, closeTo(2, 0.3));
    });
  });

  group('board', () {
    test('placement bounds and overlap', () {
      final b = Board();
      expect(b.canPlace(p('i5h'), 0, 3), isTrue);
      expect(b.canPlace(p('i5h'), 0, 4), isFalse); // off the right edge
      expect(b.canPlace(p('i5v'), 4, 0), isFalse); // off the bottom
      expect(b.canPlace(p('dot'), -1, 0), isFalse);
      b.place(p('o2'), 0, 0);
      expect(b.canPlace(p('dot'), 1, 1), isFalse);
      expect(b.canPlace(p('dot'), 2, 2), isTrue);
    });

    test('a full row and a full column clear together, crossing cell counted once', () {
      final b = Board();
      fillRow(b, 3, except: 5);
      for (var r = 0; r < Board.size; r++) {
        if (r != 3) b.cells[r * Board.size + 5] = 2;
      }
      final clear = b.place(p('dot'), 3, 5);
      expect(clear.rows, [3]);
      expect(clear.cols, [5]);
      expect(b.isEmpty, isTrue);
    });

    test('preview does not change the board', () {
      final b = Board();
      fillRow(b, 7, except: 0);
      final before = List.of(b.cells);
      expect(b.preview(p('dot'), 7, 0).rows, [7]);
      expect(b.cells, before);
    });

    test('canPlaceAnywhere detects a blocked piece', () {
      final b = Board();
      for (var r = 0; r < Board.size; r++) {
        for (var c = 0; c < Board.size; c++) {
          if ((r + c).isEven) b.cells[r * Board.size + c] = 1; // checkerboard
        }
      }
      expect(b.canPlaceAnywhere(p('dot')), isTrue);
      expect(b.canPlaceAnywhere(p('i2h')), isFalse);
    });
  });

  group('game', () {
    test('placing scores one point per cell and refills the tray after 3 pieces', () {
      final g = Game.classic(random: Random(3));
      final first = List.of(g.tray);
      var row = 0;
      for (var slot = 0; slot < 3; slot++) {
        final piece = g.tray[slot]!;
        final move = g.place(slot, row, 0);
        expect(move.points, piece.size);
        row += piece.rows;
      }
      expect(g.score, first.fold<int>(0, (s, p) => s + p!.size));
      expect(g.tray.every((p) => p != null), isTrue);
    });

    test('clearing scores lines² × 10 × combo, combo grows and decays', () {
      final g = Game.classic(random: Random(1));
      fillRow(g.board, 0, except: 7);
      g.tray[0] = p('dot');
      var m = g.place(0, 0, 7);
      expect(m.combo, 1);
      expect(m.points, 1 + 10 * 1 * 1 * 1 + 300); // board emptied: perfect clear

      fillRow(g.board, 0, except: 7);
      fillRow(g.board, 1, except: 7);
      g.tray[0] = p('i2v');
      m = g.place(0, 0, 7);
      expect(m.combo, 2);
      expect(m.points, 2 + 10 * 2 * 2 * 2 + 300);
      expect(g.bestCombo, 2);
      expect(g.linesCleared, 3);

      for (var i = 0; i < Game.comboGrace; i++) {
        g.tray[0] = p('dot');
        g.place(0, 7, i);
      }
      expect(g.combo, 0);
      expect(g.bestCombo, 2);
    });

    test('game over when no tray piece fits, revive deals fitting pieces', () {
      final g = Game.classic(random: Random(5));
      for (var r = 0; r < Board.size; r++) {
        for (var c = 0; c < Board.size; c++) {
          if ((r + c).isEven) g.board.cells[r * Board.size + c] = 1;
        }
      }
      g.tray.setAll(0, [p('o2'), p('i3h'), p('l3a')]);
      expect(g.isOver, isTrue);
      g.revive();
      expect(g.isOver, isFalse);
      expect(g.revived, isTrue);
      expect(g.tray.every((piece) => piece != null && g.board.canPlaceAnywhere(piece)), isTrue);
    });

    test('daily games deal the same sequence for everyone, different days differ', () {
      List<String> sequence(Game g) {
        final ids = <String>[];
        for (var set = 0; set < 5; set++) {
          ids.addAll(g.tray.map((p) => p!.id));
          for (var slot = 0; slot < 3; slot++) {
            g.board.cells.fillRange(0, g.board.cells.length, 0);
            g.place(slot, 0, 0);
          }
        }
        return ids;
      }

      expect(sequence(Game.daily(42)), sequence(Game.daily(42)));
      expect(sequence(Game.daily(42)), isNot(sequence(Game.daily(43))));
    });

    test('classic dealing gives at least one piece that fits', () {
      final g = Game.classic(random: Random(9));
      for (var r = 0; r < Board.size; r++) {
        for (var c = 0; c < Board.size; c++) {
          if (!(r == 7 && c == 7)) g.board.cells[r * Board.size + c] = 1;
        }
      }
      g.board.cells[7 * Board.size + 7] = 0;
      // Fill the board except one cell; force a new deal.
      g.tray.fillRange(0, 3, null);
      g.tray[0] = p('dot');
      g.place(0, 7, 7); // clears row 7 and col 7, then deals
      expect(g.tray.any((piece) => g.board.canPlaceAnywhere(piece!)), isTrue);
    });

    test('daily number counts days from launch', () {
      expect(dailyNumberFor(DateTime(2026, 10, 20)), 1);
      expect(dailyNumberFor(DateTime(2026, 10, 21, 23, 59)), 2);
      expect(dailyNumberFor(DateTime(2027, 10, 20)), 366);
    });
  });

  group('save', () {
    test('classic game round-trips through JSON', () {
      final g = Game.classic(random: Random(2));
      g.place(0, 0, 0);
      g.revived = true;
      final restored = gameFromJson(g.toJson());
      expect(restored.board.cells, g.board.cells);
      expect(restored.tray.map((p) => p?.id), g.tray.map((p) => p?.id));
      expect([restored.score, restored.combo, restored.bestCombo, restored.linesCleared],
          [g.score, g.combo, g.bestCombo, g.linesCleared]);
      expect(restored.revived, isTrue);
    });

    test('a restored daily continues the same piece sequence', () {
      Game playSets(Game g, int sets) {
        for (var i = 0; i < sets; i++) {
          for (var slot = 0; slot < 3; slot++) {
            g.board.cells.fillRange(0, g.board.cells.length, 0);
            g.place(slot, 0, 0);
          }
        }
        return g;
      }

      final original = playSets(Game.daily(7), 3);
      final restored = gameFromJson(original.toJson());
      playSets(original, 2);
      playSets(restored, 2);
      expect(restored.tray.map((p) => p!.id), original.tray.map((p) => p!.id));
    });

    test('a clear is perfect only when it empties the board', () {
      final g = Game.classic(random: Random(1));
      fillRow(g.board, 0, except: 7);
      g.tray[0] = p('dot');
      expect(g.place(0, 0, 7).perfect, isTrue);

      fillRow(g.board, 0, except: 7);
      g.board.cells[5 * Board.size + 5] = 2; // a leftover block
      g.tray[0] = p('dot');
      expect(g.place(0, 0, 7).perfect, isFalse);
    });
  });
}
