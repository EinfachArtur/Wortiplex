import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/economy/daily_reward.dart';

void main() {
  const reward = DailyLoginReward(baseCoins: 10, streakBonusPerDay: 2, maxStreakBonusDays: 7);

  test('is available when never claimed', () {
    expect(reward.isAvailable(null), isTrue);
  });

  test('is not available again on the same calendar day', () {
    final now = DateTime(2024, 5, 10, 9);
    final claimedEarlierToday = DateTime(2024, 5, 10, 1);
    expect(reward.isAvailable(claimedEarlierToday, now: now), isFalse);
  });

  test('is available again on the next calendar day', () {
    final now = DateTime(2024, 5, 11, 0, 1);
    final claimedYesterday = DateTime(2024, 5, 10, 23, 59);
    expect(reward.isAvailable(claimedYesterday, now: now), isTrue);
  });

  test('streak continues on consecutive days and resets after a gap', () {
    final now = DateTime(2024, 5, 11);
    expect(reward.continuesStreak(DateTime(2024, 5, 10), now: now), isTrue);
    expect(reward.continuesStreak(DateTime(2024, 5, 9), now: now), isFalse);
    expect(reward.nextStreak(3, DateTime(2024, 5, 10), now: now), 4);
    expect(reward.nextStreak(3, DateTime(2024, 5, 9), now: now), 1);
  });

  test('coins scale with streak up to the cap', () {
    expect(reward.coinsForStreak(1), 10);
    expect(reward.coinsForStreak(2), 12);
    expect(reward.coinsForStreak(100), 10 + 7 * 2);
  });
}
