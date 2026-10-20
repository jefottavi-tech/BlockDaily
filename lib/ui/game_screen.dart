import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/board.dart';
import '../game/game.dart';
import '../services/ad_service.dart';
import '../services/share_text.dart';
import '../services/stats_store.dart';
import 'board_view.dart';
import 'palette.dart';
import 'services.dart';
import 'share.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.game});

  final Game game;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late Game game = widget.game;
  final _stackKey = GlobalKey();
  final _boardKey = GlobalKey();

  // Drag state.
  int? _dragSlot;
  Offset _dragGlobal = Offset.zero;
  Ghost? _ghost;
  double _cell = 32;

  // Effects.
  late final _clearAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late final _popupAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  List<FlashCell> _flash = const [];
  String _popup = '';

  bool _over = false;
  bool _recorded = false;
  bool _newBest = false;

  late StatsStore _stats;
  late AdService _ads;

  bool get _isDaily => game.mode == GameMode.daily;
  bool get _canRevive => !_isDaily && !game.revived;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = Services.of(context);
    _stats = services.stats;
    _ads = services.ads;
  }

  @override
  void dispose() {
    // Leaving a daily midway still uses today's attempt.
    if (_isDaily && game.score > 0) _record();
    _clearAnim.dispose();
    _popupAnim.dispose();
    super.dispose();
  }

  double get _lift => _cell * 1.6;

  // ---- dragging ----

  void _dragStart(int slot, Offset global) {
    if (_over || game.tray[slot] == null) return;
    setState(() {
      _dragSlot = slot;
      _dragGlobal = global;
      _ghost = _target();
    });
  }

  void _dragUpdate(Offset global) {
    if (_dragSlot == null) return;
    setState(() {
      _dragGlobal = global;
      _ghost = _target();
    });
  }

  void _dragEnd() {
    final ghost = _ghost, slot = _dragSlot;
    setState(() {
      _dragSlot = null;
      _ghost = null;
    });
    if (ghost != null && slot != null) _place(slot, ghost);
  }

  /// Board cell under the dragged piece's top-left corner, if the piece fits there.
  Ghost? _target() {
    final piece = game.tray[_dragSlot!]!;
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final topLeft = _dragGlobal - Offset(piece.cols * _cell / 2, piece.rows * _cell + _lift);
    final local = box.globalToLocal(topLeft) - const Offset(BoardPainter.padding, BoardPainter.padding);
    final row = (local.dy / _cell).round(), col = (local.dx / _cell).round();
    if (!game.board.canPlace(piece, row, col)) return null;
    return Ghost(piece, row, col, game.board.preview(piece, row, col));
  }

  void _place(int slot, Ghost ghost) {
    // Snapshot the colors of the lines about to clear, for the animation.
    final after = Board.from(game.board);
    for (final c in ghost.piece.cells) {
      after.cells[(ghost.row + c.r) * Board.size + ghost.col + c.c] = ghost.piece.color;
    }
    final flash = [
      for (var r = 0; r < Board.size; r++)
        for (var c = 0; c < Board.size; c++)
          if (ghost.clear.contains(r, c)) (r: r, c: c, color: after.at(r, c)),
    ];

    final move = game.place(slot, ghost.row, ghost.col);
    if (move.clear.isEmpty) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.mediumImpact();
      _flash = flash;
      _clearAnim.forward(from: 0);
      _popup = [
        '+${move.points}',
        if (move.clear.lines > 1) '${move.clear.lines} lines!',
        if (move.combo > 1) 'Combo x${move.combo}',
      ].join('\n');
      _popupAnim.forward(from: 0);
    }
    setState(() {});
    if (game.isOver) Future.delayed(const Duration(milliseconds: 450), _gameOver);
  }

  // ---- end of game ----

  void _gameOver() {
    if (!mounted) return;
    setState(() => _over = true);
    if (!_canRevive) _record();
  }

  Future<void> _record() async {
    if (_recorded) return;
    _recorded = true;
    if (_isDaily) {
      await _stats.recordDaily(DailyResult(
          number: game.dailyNumber!, score: game.score, bestCombo: game.bestCombo, lines: game.linesCleared));
    } else {
      final best = await _stats.recordClassic(game.score);
      if (mounted) setState(() => _newBest = best);
    }
  }

  Future<void> _revive() async {
    if (!await _ads.showRewarded()) return;
    setState(() {
      game.revive();
      _over = false;
    });
  }

  Future<void> _playAgain() async {
    await _record();
    await _ads.showInterstitial();
    setState(() {
      game = Game.classic();
      _over = _recorded = _newBest = false;
    });
  }

  Future<void> _home() async {
    final navigator = Navigator.of(context);
    await _record();
    await _ads.showInterstitial();
    navigator.pop();
  }

  Future<void> _share() async {
    final result = _stats.daily(game.dailyNumber!);
    if (result == null) return;
    await shareText(context, dailyShareText(result, streak: _stats.dailyStreak(game.dailyNumber!)));
  }

  // ---- layout ----

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final boardSize = min(constraints.maxWidth - 24, constraints.maxHeight * 0.56);
          _cell = BoardPainter.cellSize(boardSize);
          final trayCell = _cell * 0.55;
          final dragging = _dragSlot == null ? null : game.tray[_dragSlot!];
          final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
          final finger = stackBox?.globalToLocal(_dragGlobal) ?? Offset.zero;

          return Stack(
            key: _stackKey,
            children: [
              Column(
                children: [
                  _TopBar(
                    title: _isDaily ? 'Daily #${game.dailyNumber}' : null,
                    score: game.score,
                    best: max(stats.bestScore, _isDaily ? 0 : game.score),
                    showBest: !_isDaily,
                    combo: game.combo,
                    onBack: () => Navigator.maybePop(context),
                  ),
                  const Spacer(),
                  SizedBox.square(
                    dimension: boardSize,
                    child: AnimatedBuilder(
                      animation: _clearAnim,
                      builder: (context, _) => CustomPaint(
                        key: _boardKey,
                        painter: BoardPainter(board: game.board, ghost: _ghost, flash: _flash, flashT: _clearAnim.value),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: trayCell * 5 + 16,
                    child: Row(children: [
                      for (var slot = 0; slot < 3; slot++)
                        Expanded(
                          child: GestureDetector(
                            key: Key('slot-$slot'),
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (d) => _dragStart(slot, d.globalPosition),
                            onPanUpdate: (d) => _dragUpdate(d.globalPosition),
                            onPanEnd: (_) => _dragEnd(),
                            onPanCancel: _dragEnd,
                            child: Center(
                              child: game.tray[slot] == null || slot == _dragSlot
                                  ? const SizedBox.shrink()
                                  : PieceView(
                                      piece: game.tray[slot]!,
                                      cell: trayCell,
                                      opacity: game.board.canPlaceAnywhere(game.tray[slot]!) ? 1 : 0.35,
                                    ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 56), // reserved for the banner ad
                ],
              ),
              // Score popup above the board.
              Positioned(
                left: 0,
                right: 0,
                top: constraints.maxHeight * 0.16,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _popupAnim,
                    builder: (context, _) {
                      final t = _popupAnim.value;
                      if (t == 0 || t == 1) return const SizedBox.shrink();
                      return Opacity(
                        opacity: (1 - t) * 1.2 > 1 ? 1 : (1 - t) * 1.2,
                        child: Transform.translate(
                          offset: Offset(0, -40 * t),
                          child: Text(
                            _popup,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: accent,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              shadows: [Shadow(blurRadius: 12, color: Colors.black54)],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (dragging != null)
                Positioned(
                  left: finger.dx - dragging.cols * _cell / 2,
                  top: finger.dy - dragging.rows * _cell - _lift,
                  child: IgnorePointer(child: PieceView(piece: dragging, cell: _cell, opacity: 0.95)),
                ),
              if (_over)
                _GameOverPanel(
                  daily: _isDaily,
                  score: game.score,
                  best: stats.bestScore,
                  newBest: _newBest,
                  canRevive: _canRevive,
                  onRevive: _revive,
                  onPlayAgain: _playAgain,
                  onHome: _home,
                  onShare: _share,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.score,
    required this.best,
    required this.showBest,
    required this.combo,
    required this.onBack,
  });

  final String? title;
  final int score;
  final int best;
  final bool showBest;
  final int combo;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Column(children: [
        Row(children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70)),
          if (title != null)
            Text(title!, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          if (showBest) ...[
            const Icon(Icons.emoji_events_rounded, color: accent, size: 22),
            const SizedBox(width: 4),
            Text(formatScore(best),
                key: const Key('best'), style: const TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ]),
        Text(
          formatScore(score),
          key: const Key('score'),
          style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900),
        ),
        SizedBox(
          height: 22,
          child: combo > 1
              ? Text('🔥 Combo x$combo', style: const TextStyle(color: Color(0xFFFF8A3D), fontWeight: FontWeight.w800))
              : null,
        ),
      ]),
    );
  }
}

class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({
    required this.daily,
    required this.score,
    required this.best,
    required this.newBest,
    required this.canRevive,
    required this.onRevive,
    required this.onPlayAgain,
    required this.onHome,
    required this.onShare,
  });

  final bool daily;
  final int score;
  final int best;
  final bool newBest;
  final bool canRevive;
  final VoidCallback onRevive;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final big = FilledButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: background,
      minimumSize: const Size.fromHeight(52),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
    final small = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.white38),
      minimumSize: const Size.fromHeight(48),
    );
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(daily ? 'Daily complete!' : 'No more space',
                  style: const TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(formatScore(score),
                  key: const Key('finalScore'),
                  style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900)),
              if (newBest)
                const Text('🏆 New best!', style: TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.w800))
              else if (!daily)
                Text('Best ${formatScore(best)}', style: const TextStyle(color: accent, fontSize: 16)),
              const SizedBox(height: 28),
              if (canRevive) ...[
                FilledButton.icon(
                  key: const Key('revive'),
                  style: big,
                  onPressed: onRevive,
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: const Text('Continue  ▶ ad'),
                ),
                const SizedBox(height: 12),
              ],
              if (daily)
                FilledButton.icon(
                  key: const Key('share'),
                  style: big,
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Share result'),
                )
              else
                OutlinedButton(key: const Key('again'), style: small, onPressed: onPlayAgain, child: const Text('Play again')),
              const SizedBox(height: 12),
              OutlinedButton(key: const Key('home'), style: small, onPressed: onHome, child: const Text('Home')),
            ]),
          ),
        ),
      ),
    );
  }
}
