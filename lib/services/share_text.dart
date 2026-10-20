import 'stats_store.dart';

String formatScore(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');

/// Text players paste into chats and social posts after the daily puzzle.
String dailyShareText(DailyResult r, {required int streak}) {
  final fire = '🔥' * r.bestCombo.clamp(0, 5);
  return [
    'Block Daily #${r.number} 🧩',
    '⭐ ${formatScore(r.score)}',
    if (r.bestCombo > 0) '$fire combo x${r.bestCombo} · ${r.lines} lines',
    if (streak > 1) '📅 $streak-day streak',
  ].join('\n');
}
