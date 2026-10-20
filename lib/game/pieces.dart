import 'dart:math';

/// A cell offset inside a piece: (row, col).
typedef Cell = ({int r, int c});

/// A block shape. [color] indexes the palette (1-based; 0 means empty on the board).
class Piece {
  const Piece(this.id, this.cells, this.color, {this.weight = 1});

  final String id;
  final List<Cell> cells;
  final int color;

  /// Relative frequency when dealing random pieces.
  final int weight;

  int get rows => cells.map((c) => c.r).reduce(max) + 1;
  int get cols => cells.map((c) => c.c).reduce(max) + 1;
  int get size => cells.length;
}

List<Cell> _parse(String art) {
  final lines = art.trim().split('\n');
  return [
    for (var r = 0; r < lines.length; r++)
      for (var c = 0; c < lines[r].length; c++)
        if (lines[r][c] == '#') (r: r, c: c),
  ];
}

Piece _p(String id, String art, int color, {int weight = 1}) => Piece(id, _parse(art), color, weight: weight);

/// The full piece set. Small and straight pieces are weighted up so boards stay playable.
final List<Piece> allPieces = [
  _p('dot', '#', 1, weight: 2),
  _p('i2h', '##', 2, weight: 2),
  _p('i2v', '#\n#', 2, weight: 2),
  _p('i3h', '###', 3, weight: 2),
  _p('i3v', '#\n#\n#', 3, weight: 2),
  _p('i4h', '####', 4),
  _p('i4v', '#\n#\n#\n#', 4),
  _p('i5h', '#####', 5),
  _p('i5v', '#\n#\n#\n#\n#', 5),
  _p('o2', '##\n##', 6, weight: 2),
  _p('o3', '###\n###\n###', 7),
  _p('l3a', '#.\n##', 8),
  _p('l3b', '.#\n##', 8),
  _p('l3c', '##\n#.', 8),
  _p('l3d', '##\n.#', 8),
  _p('l5a', '#..\n#..\n###', 9),
  _p('l5b', '..#\n..#\n###', 9),
  _p('l5c', '###\n#..\n#..', 9),
  _p('l5d', '###\n..#\n..#', 9),
  _p('ta', '###\n.#.', 10),
  _p('tb', '.#.\n###', 10),
  _p('tc', '#.\n##\n#.', 10),
  _p('td', '.#\n##\n.#', 10),
  _p('sa', '.##\n##.', 11),
  _p('sb', '##.\n.##', 11),
  _p('sc', '#.\n##\n.#', 11),
  _p('sd', '.#\n##\n#.', 11),
  _p('la', '#.\n#.\n##', 12),
  _p('lb', '.#\n.#\n##', 12),
  _p('lc', '##\n#.\n#.', 12),
  _p('ld', '##\n.#\n.#', 12),
];

final Map<String, Piece> piecesById = {for (final p in allPieces) p.id: p};

final int _totalWeight = allPieces.fold(0, (sum, p) => sum + p.weight);

Piece randomPiece(Random rng) {
  var roll = rng.nextInt(_totalWeight);
  for (final p in allPieces) {
    roll -= p.weight;
    if (roll < 0) return p;
  }
  return allPieces.last;
}
