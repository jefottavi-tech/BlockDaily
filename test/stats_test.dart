import 'package:block_daily/services/share_text.dart';
import 'package:block_daily/services/stats_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StatsStore stats;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    stats = await StatsStore.open();
  });

  test('best score only goes up', () async {
    expect(await stats.recordClassic(120), isTrue);
    expect(await stats.recordClassic(80), isFalse);
    expect(stats.bestScore, 120);
    expect(stats.gamesPlayed, 2);
  });

  test('daily keeps the first attempt and counts the streak', () async {
    const r = DailyResult(number: 10, score: 500, bestCombo: 3, lines: 9);
    await stats.recordDaily(r);
    await stats.recordDaily(const DailyResult(number: 10, score: 9999, bestCombo: 9, lines: 99));
    expect(stats.daily(10)!.score, 500);

    await stats.recordDaily(const DailyResult(number: 9, score: 1, bestCombo: 0, lines: 0));
    await stats.recordDaily(const DailyResult(number: 7, score: 1, bestCombo: 0, lines: 0));
    expect(stats.dailyStreak(10), 2); // 10, 9 (8 missing)
    expect(stats.dailyStreak(11), 2); // today not played yet: still counts up to yesterday
    expect(stats.dailyStreak(12), 0);
  });

  test('share text', () {
    expect(formatScore(1234567), '1,234,567');
    expect(formatScore(999), '999');
    const r = DailyResult(number: 42, score: 3450, bestCombo: 7, lines: 24);
    expect(dailyShareText(r, streak: 5), 'Block Daily #42 🧩\n⭐ 3,450\n🔥🔥🔥🔥🔥 combo x7 · 24 lines\n📅 5-day streak\n$playStoreUrl');
    expect(dailyShareText(const DailyResult(number: 1, score: 12, bestCombo: 0, lines: 0), streak: 1),
        'Block Daily #1 🧩\n⭐ 12\n$playStoreUrl');
    expect(classicShareText(score: 18240, newBest: true), 'Block Daily 🧩\n🏆 New best: 18,240\n$playStoreUrl');
    expect(classicShareText(score: 950, newBest: false), 'Block Daily 🧩\n⭐ 950\n$playStoreUrl');
  });
}
