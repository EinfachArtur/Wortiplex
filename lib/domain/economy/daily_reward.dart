bool isSameCalendarDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Once-per-calendar-day login bonus. Pure function of the last claim
/// timestamp so it is trivially testable without mocking a clock service.
class DailyLoginReward {
  final int baseCoins;
  final int streakBonusPerDay;
  final int maxStreakBonusDays;

  const DailyLoginReward({
    this.baseCoins = 10,
    this.streakBonusPerDay = 2,
    this.maxStreakBonusDays = 7,
  });

  bool isAvailable(DateTime? lastClaimedAt, {DateTime? now}) {
    if (lastClaimedAt == null) return true;
    return !isSameCalendarDay(lastClaimedAt, now ?? DateTime.now());
  }

  /// Whether claiming today continues yesterday's streak (vs. resetting it).
  bool continuesStreak(DateTime? lastClaimedAt, {DateTime? now}) {
    if (lastClaimedAt == null) return false;
    final n = now ?? DateTime.now();
    final yesterday = DateTime(n.year, n.month, n.day - 1);
    return isSameCalendarDay(lastClaimedAt, yesterday);
  }

  int nextStreak(int currentStreak, DateTime? lastClaimedAt, {DateTime? now}) {
    return continuesStreak(lastClaimedAt, now: now) ? currentStreak + 1 : 1;
  }

  int coinsForStreak(int streak) {
    final bonusDays = (streak - 1).clamp(0, maxStreakBonusDays);
    return baseCoins + bonusDays * streakBonusPerDay;
  }
}
