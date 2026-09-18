import 'dart:math';

import 'daily_reward.dart';

/// A single wedge on the spin wheel.
class SpinOutcome {
  final int coins;
  final double weight; // relative probability weight, weights need not sum to 1
  const SpinOutcome({required this.coins, required this.weight});
}

/// Once-per-calendar-day weighted random coin reward.
class SpinWheel {
  final List<SpinOutcome> outcomes;

  const SpinWheel({
    this.outcomes = const [
      SpinOutcome(coins: 10, weight: 30),
      SpinOutcome(coins: 20, weight: 25),
      SpinOutcome(coins: 30, weight: 20),
      SpinOutcome(coins: 50, weight: 15),
      SpinOutcome(coins: 100, weight: 8),
      SpinOutcome(coins: 250, weight: 2),
    ],
  });

  bool isAvailable(DateTime? lastSpinAt, {DateTime? now}) {
    if (lastSpinAt == null) return true;
    return !isSameCalendarDay(lastSpinAt, now ?? DateTime.now());
  }

  SpinOutcome spin({Random? random}) {
    final rng = random ?? Random();
    final totalWeight = outcomes.fold<double>(0, (sum, o) => sum + o.weight);
    var roll = rng.nextDouble() * totalWeight;
    for (final outcome in outcomes) {
      if (roll < outcome.weight) return outcome;
      roll -= outcome.weight;
    }
    return outcomes.last;
  }
}
