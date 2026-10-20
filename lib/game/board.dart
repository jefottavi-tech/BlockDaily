import 'pieces.dart';

/// Lines that a placement fills, before they are cleared.
class Clear {
  const Clear(this.rows, this.cols);

  final List<int> rows;
  final List<int> cols;

  int get lines => rows.length + cols.length;
  bool get isEmpty => lines == 0;

  bool contains(int r, int c) => rows.contains(r) || cols.contains(c);
}

/// 8×8 grid. Each cell holds 0 (empty) or a palette color.
class Board {
  Board() : cells = List.filled(size * size, 0);

  Board.from(Board other) : cells = List.of(other.cells);

  static const size = 8;
  final List<int> cells;

  int at(int r, int c) => cells[r * size + c];

  bool get isEmpty => cells.every((v) => v == 0);

  bool canPlace(Piece p, int row, int col) {
    for (final cell in p.cells) {
      final r = row + cell.r, c = col + cell.c;
      if (r < 0 || c < 0 || r >= size || c >= size || at(r, c) != 0) return false;
    }
    return true;
  }

  bool canPlaceAnywhere(Piece p) {
    for (var r = 0; r <= size - p.rows; r++) {
      for (var c = 0; c <= size - p.cols; c++) {
        if (canPlace(p, r, c)) return true;
      }
    }
    return false;
  }

  /// Rows and columns that would be full after placing [p] at (row, col), without changing the board.
  Clear preview(Piece p, int row, int col) {
    final filled = {for (final cell in p.cells) (row + cell.r) * size + col + cell.c};
    bool full(int r, int c) => at(r, c) != 0 || filled.contains(r * size + c);
    return Clear(
      [for (var r = 0; r < size; r++) if (List.generate(size, (c) => full(r, c)).every((f) => f)) r],
      [for (var c = 0; c < size; c++) if (List.generate(size, (r) => full(r, c)).every((f) => f)) c],
    );
  }

  /// Places [p] and clears the completed lines. Caller must check [canPlace] first.
  Clear place(Piece p, int row, int col) {
    final clear = preview(p, row, col);
    for (final cell in p.cells) {
      cells[(row + cell.r) * size + col + cell.c] = p.color;
    }
    for (final r in clear.rows) {
      for (var c = 0; c < size; c++) {
        cells[r * size + c] = 0;
      }
    }
    for (final c in clear.cols) {
      for (var r = 0; r < size; r++) {
        cells[r * size + c] = 0;
      }
    }
    return clear;
  }
}
