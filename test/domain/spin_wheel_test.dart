import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/economy/spin_wheel.dart';

void main() {
  const wheel = SpinWheel();

  test('free spin is available when never spun', () {
    expect(wheel.isFreeSpinAvailable(null), isTrue);
  });

  test('free spin is used up for the rest of the calendar day', () {
    final now = DateTime(2024, 5, 10, 20);
    expect(wheel.isFreeSpinAvailable(DateTime(2024, 5, 10, 8), now: now), isFalse);
    expect(wheel.isFreeSpinAvailable(DateTime(2024, 5, 9, 23), now: now), isTrue);
  });

  test('wheel has 8 wedges and no two neighbours share a prize kind', () {
    final w = wheel.wedges;
    expect(w.length, 8);
    for (var i = 0; i < w.length; i++) {
      expect(w[i].kind == w[(i + 1) % w.length].kind, isFalse, reason: 'wedge $i');
    }
  });

  test('spin always returns a real wedge index with its prize', () {
    final rng = Random(42);
    for (var i = 0; i < 200; i++) {
      final result = wheel.spin(random: rng);
      expect(result.index, inInclusiveRange(0, wheel.wedges.length - 1));
      expect(identical(result.prize, wheel.wedges[result.index]), isTrue);
    }
  });

  test('a roll of 0 lands on the first wedge', () {
    expect(wheel.spin(random: _FixedRandom(0)).index, 0);
  });

  test('heavier wedges are hit more often than the 250 coin jackpot', () {
    final rng = Random(7);
    final hits = List.filled(wheel.wedges.length, 0);
    for (var i = 0; i < 5000; i++) {
      hits[wheel.spin(random: rng).index]++;
    }
    expect(hits[6], greaterThan(hits[0])); // 25 coins (weight 20) vs 250 coins (weight 2)
  });
}

class _FixedRandom implements Random {
  final double value;
  const _FixedRandom(this.value);

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}
