import 'package:flutter/material.dart';

/// Block colors by piece color index (1-based).
const blockColors = <Color>[
  Color(0x00000000),
  Color(0xFFFFC93C), // dot
  Color(0xFF4FC3F7), // 2-line
  Color(0xFF7C4DFF), // 3-line
  Color(0xFFFF5370), // 4-line
  Color(0xFFFF8A3D), // 5-line
  Color(0xFF4ADE80), // 2×2
  Color(0xFF2DD4BF), // 3×3
  Color(0xFFF472B6), // small L
  Color(0xFF60A5FA), // big L
  Color(0xFFA78BFA), // T
  Color(0xFFFB7185), // S
  Color(0xFFFACC15), // L
];

const background = Color(0xFF16213E);
const boardColor = Color(0xFF0F172A);
const emptyCell = Color(0xFF1E293B);
const accent = Color(0xFFFFC93C);

/// Draws one block with a light top edge and darker bottom, so cells read as tiles.
void paintBlock(Canvas canvas, Rect rect, Color color, {double opacity = 1}) {
  final r = RRect.fromRectAndRadius(rect.deflate(rect.width * 0.04), Radius.circular(rect.width * 0.16));
  canvas.drawRRect(r, Paint()..color = color.withValues(alpha: opacity));
  final inset = rect.width * 0.14;
  final shine = RRect.fromRectAndRadius(
    Rect.fromLTWH(rect.left + inset, rect.top + inset * 0.7, rect.width - inset * 2, rect.height * 0.22),
    Radius.circular(rect.width * 0.1),
  );
  canvas.drawRRect(shine, Paint()..color = Colors.white.withValues(alpha: 0.28 * opacity));
}
