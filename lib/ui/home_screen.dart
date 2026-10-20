import 'package:flutter/material.dart';

import '../game/game.dart';
import '../game/pieces.dart';
import '../services/share_text.dart';
import 'board_view.dart';
import 'game_screen.dart';
import 'palette.dart';
import 'services.dart';
import 'share.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _open(Game game) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GameScreen(game: game)));
    if (mounted) setState(() {}); // refresh best score and daily status
  }

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final stats = services.stats;
    final today = dailyNumberFor(services.today());
    final daily = stats.daily(today);
    final streak = stats.dailyStreak(today);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Spacer(),
                const _Logo(),
                const SizedBox(height: 12),
                const Text('BLOCK DAILY',
                    style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.emoji_events_rounded, color: accent),
                  const SizedBox(width: 6),
                  Text(formatScore(stats.bestScore),
                      key: const Key('homeBest'),
                      style: const TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.w800)),
                ]),
                const Spacer(),
                FilledButton(
                  key: const Key('play'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: background,
                    minimumSize: const Size.fromHeight(64),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  onPressed: () => _open(Game.classic()),
                  child: const Text('PLAY'),
                ),
                const SizedBox(height: 16),
                _DailyCard(
                  number: today,
                  score: daily?.score,
                  streak: streak,
                  onPlay: () => _open(Game.daily(today)),
                  onShare: daily == null
                      ? null
                      : () => shareText(context, dailyShareText(daily, streak: streak)),
                ),
                const Spacer(),
                const Text(
                  'Drag blocks onto the board. Fill rows or columns to clear them.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.number, required this.score, required this.streak, required this.onPlay, this.onShare});

  final int number;
  final int? score;
  final int streak;
  final VoidCallback onPlay;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final played = score != null;
    return Material(
      color: const Color(0xFF243B6B),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const Key('daily'),
        borderRadius: BorderRadius.circular(20),
        onTap: played ? onShare : onPlay,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Daily #$number',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  played ? 'Score ${formatScore(score!)} · tap to share' : 'Same pieces for everyone today',
                  style: const TextStyle(color: Colors.white70),
                ),
              ]),
            ),
            if (streak > 0) Text('🔥 $streak', style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(width: 8),
            Icon(played ? Icons.ios_share_rounded : Icons.play_arrow_rounded, color: accent, size: 30),
          ]),
        ),
      ),
    );
  }
}

/// A few blocks as the logo.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (final id in ['l3a', 'o2', 'tb'])
          Padding(padding: const EdgeInsets.all(4), child: PieceView(piece: piecesById[id]!, cell: 26)),
      ]);
}
