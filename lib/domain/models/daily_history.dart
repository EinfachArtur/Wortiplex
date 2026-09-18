import 'language.dart';

/// Result of every played daily puzzle, keyed by language and calendar date.
/// A missing entry means the day was not played.
class DailyHistory {
  final Map<String, bool> _results; // "de_2026-09-18" -> won?

  const DailyHistory([this._results = const {}]);

  static String keyFor(Language language, DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${language.code}_${date.year}-$m-$d';
  }

  /// null = not played, true = won, false = lost.
  bool? resultFor(Language language, DateTime date) => _results[keyFor(language, date)];

  bool hasPlayed(Language language, DateTime date) => resultFor(language, date) != null;

  int winsInMonth(Language language, int year, int month) {
    var wins = 0;
    final days = DateTime(year, month + 1, 0).day;
    for (var day = 1; day <= days; day++) {
      if (resultFor(language, DateTime(year, month, day)) == true) wins++;
    }
    return wins;
  }

  DailyHistory withResult(Language language, DateTime date, {required bool won}) {
    return DailyHistory({..._results, keyFor(language, date): won});
  }

  Map<String, bool> toMap() => Map.of(_results);

  factory DailyHistory.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const DailyHistory();
    return DailyHistory({for (final e in map.entries) e.key.toString(): e.value == true});
  }
}
