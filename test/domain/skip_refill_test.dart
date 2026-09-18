import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/economy/skip_refill.dart';

void main() {
  const calc = SkipRefillCalculator(maxAllowance: 3, refillInterval: Duration(hours: 8));

  test('does not refill while at max and timer is not running', () {
    final state = calc.refill(const SkipState(available: 3, refillStartedAt: null));
    expect(state.available, 3);
    expect(state.refillStartedAt, isNull);
  });

  test('consume starts the regeneration timer', () {
    final now = DateTime(2024, 1, 1, 12);
    final state = calc.consume(const SkipState(available: 3, refillStartedAt: null), now: now);
    expect(state.available, 2);
    expect(state.refillStartedAt, now);
  });

  test('refill grants one charge after exactly one interval', () {
    final start = DateTime(2024, 1, 1, 12);
    final consumed = SkipState(available: 2, refillStartedAt: start);
    final refilled = calc.refill(consumed, now: start.add(const Duration(hours: 8)));
    expect(refilled.available, 3);
    expect(refilled.refillStartedAt, isNull); // back at max, timer stops
  });

  test('refill grants no charge before the interval elapses', () {
    final start = DateTime(2024, 1, 1, 12);
    final consumed = SkipState(available: 1, refillStartedAt: start);
    final refilled = calc.refill(consumed, now: start.add(const Duration(hours: 7)));
    expect(refilled.available, 1);
    expect(refilled.refillStartedAt, start);
  });

  test('refill caps at max allowance even with excess elapsed time', () {
    final start = DateTime(2024, 1, 1, 12);
    final consumed = SkipState(available: 0, refillStartedAt: start);
    final refilled = calc.refill(consumed, now: start.add(const Duration(hours: 100)));
    expect(refilled.available, 3);
    expect(refilled.refillStartedAt, isNull);
  });
}
