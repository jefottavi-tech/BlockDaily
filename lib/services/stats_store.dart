import 'package:shared_preferences/shared_preferences.dart';

/// Result of a finished daily puzzle.
class DailyResult {
  const DailyResult({required this.number, required this.score, required this.bestCombo, required this.lines});

  final int number;
  final int score;
  final int bestCombo;
  final int lines;

  String encode() => '$score,$bestCombo,$lines';

  static DailyResult? decode(int number, String? raw) {
    final parts = raw?.split(',');
    if (parts == null || parts.length != 3) return null;
    return DailyResult(
      number: number,
      score: int.parse(parts[0]),
      bestCombo: int.parse(parts[1]),
      lines: int.parse(parts[2]),
    );
  }
}

class StatsStore {
  StatsStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<StatsStore> open() async => StatsStore(await SharedPreferences.getInstance());

  int get bestScore => _prefs.getInt('best') ?? 0;
  int get gamesPlayed => _prefs.getInt('games') ?? 0;

  /// Records a finished classic game; returns true for a new best score.
  Future<bool> recordClassic(int score) async {
    await _prefs.setInt('games', gamesPlayed + 1);
    if (score <= bestScore) return false;
    await _prefs.setInt('best', score);
    return true;
  }

  DailyResult? daily(int number) => DailyResult.decode(number, _prefs.getString('daily.$number'));

  /// One attempt per day: the first result is kept.
  Future<void> recordDaily(DailyResult result) async {
    if (daily(result.number) != null) return;
    await _prefs.setString('daily.${result.number}', result.encode());
  }

  /// Consecutive days with a finished daily, ending today (or yesterday if today isn't played yet).
  int dailyStreak(int today) {
    var day = daily(today) != null ? today : today - 1;
    var streak = 0;
    while (day > 0 && daily(day) != null) {
      streak++;
      day--;
    }
    return streak;
  }
}
