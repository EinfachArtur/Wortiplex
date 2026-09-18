import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/economy/spin_wheel.dart';

void main() {
  const wheel = SpinWheel();

  test('is available when never spun', () {
    expect(wheel.isAvailable(null), isTrue);
  });

  test('is not available again on the same calendar day', () {
    final now = DateTime(2024, 5, 10, 20);
    final spunEarlier = DateTime(2024, 5, 10, 8);
    expect(wheel.isAvailable(spunEarlier, now: now), isFalse);
  });

  test('spin always returns one of the configured outcomes', () {
    final rng = Random(42);
    for (var i = 0; i < 100; i++) {
      final outcome = wheel.spin(random: rng);
      expect(wheel.outcomes.map((o) => o.coins), contains(outcome.coins));
    }
  });

  test('a roll of 0 returns the first outcome', () {
    final outcome = wheel.spin(random: _FixedRandom(0));
    expect(outcome.coins, wheel.outcomes.first.coins);
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
