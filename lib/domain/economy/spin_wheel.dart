import 'dart:math';

import 'daily_reward.dart';

enum PrizeKind { coins, hint, strikeout, skip, spin }

class SpinPrize {
  final PrizeKind kind;
  final int amount;
  final double weight; // relative probability, weights need not sum to 1

  const SpinPrize(this.kind, this.amount, this.weight);
}

class SpinResult {
  final int index;
  final SpinPrize prize;
  const SpinResult(this.index, this.prize);
}

/// The wedges in clockwise visual order. Neighbouring wedges avoid the same
/// prize kind so the wheel stays colourful.
const defaultWheelWedges = <SpinPrize>[
  SpinPrize(PrizeKind.coins, 250, 2),
  SpinPrize(PrizeKind.strikeout, 1, 8),
  SpinPrize(PrizeKind.coins, 50, 16),
  SpinPrize(PrizeKind.skip, 1, 8),
  SpinPrize(PrizeKind.coins, 100, 6),
  SpinPrize(PrizeKind.hint, 1, 8),
  SpinPrize(PrizeKind.coins, 25, 22),
  SpinPrize(PrizeKind.spin, 2, 4),
];

/// Weighted random prize wheel with one free spin per calendar day.
class SpinWheel {
  final List<SpinPrize> wedges;

  const SpinWheel({this.wedges = defaultWheelWedges});

  bool isFreeSpinAvailable(DateTime? lastFreeSpinAt, {DateTime? now}) {
    if (lastFreeSpinAt == null) return true;
    return !isSameCalendarDay(lastFreeSpinAt, now ?? DateTime.now());
  }

  SpinResult spin({Random? random}) {
    final rng = random ?? Random();
    final totalWeight = wedges.fold<double>(0, (sum, w) => sum + w.weight);
    var roll = rng.nextDouble() * totalWeight;
    for (var i = 0; i < wedges.length; i++) {
      if (roll < wedges[i].weight) return SpinResult(i, wedges[i]);
      roll -= wedges[i].weight;
    }
    return SpinResult(wedges.length - 1, wedges.last);
  }
}
