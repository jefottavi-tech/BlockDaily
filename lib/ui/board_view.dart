import 'dart:math';

import 'package:flutter/material.dart';

import '../game/board.dart';
import '../game/pieces.dart';
import 'palette.dart';

/// A cell being cleared, kept for the clear animation.
typedef FlashCell = ({int r, int c, int color});

/// A spark thrown out of a cleared cell. Positions and speeds are in cell units.
class Particle {
  const Particle(this.x, this.y, this.vx, this.vy, this.color, this.size);

  final double x, y, vx, vy, size;
  final int color;

  static const gravity = 9.0;

  /// Sparks for the cleared cells; more of them for bigger clears.
  static List<Particle> burst(List<FlashCell> cells, {required int lines, int seed = 0}) {
    final rng = Random(seed);
    final perCell = (2 + lines).clamp(3, 6);
    return [
      for (final c in cells)
        for (var i = 0; i < perCell; i++)
          Particle(
            c.c + 0.5,
            c.r + 0.5,
            (rng.nextDouble() - 0.5) * 6,
            -rng.nextDouble() * 5 - 1,
            c.color,
            0.18 + rng.nextDouble() * 0.2,
          ),
    ];
  }
}

/// Where the dragged piece would land.
class Ghost {
  const Ghost(this.piece, this.row, this.col, this.clear);

  final Piece piece;
  final int row;
  final int col;
  final Clear clear;
}

class BoardPainter extends CustomPainter {
  BoardPainter({required this.board, this.ghost, this.flash = const [], this.particles = const [], this.fxT = 1});

  final Board board;
  final Ghost? ghost;
  final List<FlashCell> flash;
  final List<Particle> particles;

  /// Clear effect progress, 0 → 1: cells flash out in the first half, sparks fly the whole time.
  final double fxT;

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

    if (fxT >= 1) return;
    final flashT = min(1.0, fxT * 2);
    if (flashT < 1) {
      // Pop: swell and whiten, then shrink away.
      final scale = flashT < 0.3 ? 1 + flashT * 0.6 : max(0.0, 1.18 - (flashT - 0.3) * 1.7);
      final whiten = flashT < 0.3 ? flashT / 0.3 * 0.7 : 0.7;
      for (final f in flash) {
        final r = rect(f.r, f.c);
        paintBlock(canvas, Rect.fromCenter(center: r.center, width: r.width * scale, height: r.height * scale),
            Color.lerp(blockColors[f.color], Colors.white, whiten)!, opacity: 1 - flashT * flashT);
      }
    }
    // Sparks can fly outside the board: the canvas isn't clipped.
    final t = fxT * 0.9; // seconds-ish of flight
    final spark = Paint();
    for (final p in particles) {
      final x = padding + (p.x + p.vx * t) * cell;
      final y = padding + (p.y + p.vy * t + 0.5 * Particle.gravity * t * t) * cell;
      spark.color = blockColors[p.color].withValues(alpha: (1 - fxT).clamp(0, 1));
      final s = p.size * cell * (1 - fxT * 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: s, height: s), Radius.circular(s * 0.25)),
        spark,
      );
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
