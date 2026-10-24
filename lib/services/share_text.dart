import '../l10n/app_localizations.dart';
import 'stats_store.dart';

/// Store page, added to every shared result so friends can install the game in one tap.
const playStoreUrl = 'https://play.google.com/store/apps/details?id=ca.kallistesoft.block_daily';

/// Groups thousands: `18,240` in English, `18 240` (narrow no-break space) in French.
String formatScore(int n, {String locale = 'en'}) {
  final separator = locale.startsWith('fr') ? ' ' : ',';
  return n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => separator);
}

/// Text players paste into chats and social posts after the daily puzzle, in the player's language.
/// Pass `lookupAppLocalizations(locale)` where there is no BuildContext.
String dailyShareText(DailyResult r, {required int streak, required AppLocalizations l10n}) {
  final fire = '🔥' * r.bestCombo.clamp(0, 5);
  return [
    'Block Daily #${r.number} 🧩',
    '⭐ ${formatScore(r.score, locale: l10n.localeName)}',
    if (r.bestCombo > 0) '$fire combo x${r.bestCombo} · ${l10n.shareLines(r.lines)}',
    if (streak > 1) l10n.shareStreak(streak),
    playStoreUrl,
  ].join('\n');
}

/// Text shared after a classic game, in the player's language.
String classicShareText({required int score, required bool newBest, required AppLocalizations l10n}) {
  final formatted = formatScore(score, locale: l10n.localeName);
  return [
    'Block Daily 🧩',
    newBest ? l10n.shareNewBest(formatted) : '⭐ $formatted',
    playStoreUrl,
  ].join('\n');
}
