import '../domain/models/language.dart';

/// Deterministically picks the daily solution word per language so every
/// player sees the same puzzle on a given calendar date without a server.
class DailyPuzzleService {
  const DailyPuzzleService();

  /// The calendar day of [date] (or now) as a timezone-free key. Only the
  /// year/month/day fields count, so a local-midnight date never slips to the
  /// previous day the way it would if converted to UTC first.
  DateTime todayKey([DateTime? now]) {
    final n = now ?? DateTime.now();
    return DateTime.utc(n.year, n.month, n.day);
  }

  String solutionFor({
    required Language language,
    required List<String> solutionPool,
    DateTime? date,
  }) {
    if (solutionPool.isEmpty) {
      throw StateError('Solution pool for ${language.code} is empty.');
    }
    final day = todayKey(date);
    // Days since a fixed epoch, so the index is stable across app restarts
    // and consistent for every player regardless of timezone (UTC day key).
    final epoch = DateTime.utc(2024, 1, 1);
    final daysSinceEpoch = day.difference(epoch).inDays;
    final index = daysSinceEpoch % solutionPool.length;
    return solutionPool[index];
  }
}
