import 'package:flutter/material.dart';

import '../game/board.dart';
import '../game/pieces.dart';
import 'palette.dart';

/// A cell being cleared, kept for the clear animation.
typedef FlashCell = ({int r, int c, int color});

/// Where the dragged piece would land.
class Ghost {
  const Ghost(this.piece, this.row, this.col, this.clear);

  final Piece piece;
  final int row;
  final int col;
  final Clear clear;
}

class BoardPainter extends CustomPainter {
  BoardPainter({required this.board, this.ghost, this.flash = const [], this.flashT = 1});

  final Board board;
  final Ghost? ghost;
  final List<FlashCell> flash;

  /// Clear animation progress, 0 → 1.
  final double flashT;

  static const padding = 6.0;

  static double cellSize(double boardSize) => (boardSize - padding * 2) / Board.size;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = cellSize(size.width);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      Paint()..color = boardColor,
    );
    Rect rect(int r, int c) => Rect.fromLTWH(padding + c * cell, padding + r * cell, cell, cell);

    final g = ghost;
    final ghostCells = {if (g != null) for (final p in g.piece.cells) (g.row + p.r, g.col + p.c)};

    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        final v = board.at(r, c);
        final cellRect = rect(r, c);
        if (v == 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(cellRect.deflate(cell * 0.06), Radius.circular(cell * 0.14)),
            Paint()..color = emptyCell,
          );
        } else if (g != null && g.clear.contains(r, c)) {
          // Lines about to clear take the dragged piece's color.
          paintBlock(canvas, cellRect, blockColors[g.piece.color]);
        } else {
          paintBlock(canvas, cellRect, blockColors[v]);
        }
        if (g != null && ghostCells.contains((r, c))) {
          paintBlock(canvas, cellRect, blockColors[g.piece.color], opacity: g.clear.contains(r, c) ? 0.9 : 0.45);
        }
      }
    }

    if (flashT < 1) {
      for (final f in flash) {
        final scale = 1 - flashT * 0.6;
        final r = rect(f.r, f.c);
        paintBlock(canvas, Rect.fromCenter(center: r.center, width: r.width * scale, height: r.height * scale),
            Color.lerp(blockColors[f.color], Colors.white, 0.5)!, opacity: 1 - flashT);
      }
    }
  }

  @override
  bool shouldRepaint(BoardPainter old) => true;
}

class PieceView extends StatelessWidget {
  const PieceView({super.key, required this.piece, required this.cell, this.opacity = 1});

  final Piece piece;
  final double cell;
  final double opacity;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(piece.cols * cell, piece.rows * cell),
        painter: _PiecePainter(piece, cell, opacity),
      );
}

class _PiecePainter extends CustomPainter {
  _PiecePainter(this.piece, this.cell, this.opacity);

  final Piece piece;
  final double cell;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in piece.cells) {
      paintBlock(canvas, Rect.fromLTWH(c.c * cell, c.r * cell, cell, cell), blockColors[piece.color], opacity: opacity);
    }
  }

  @override
  bool shouldRepaint(_PiecePainter old) => old.piece != piece || old.cell != cell || old.opacity != opacity;
}
