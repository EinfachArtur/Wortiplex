import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/economy/ad_cadence.dart';

void main() {
  test('with everyNRounds 1 an ad is due after every single round', () {
    final cadence = AdCadence(everyNRounds: 1);
    for (var i = 0; i < 5; i++) {
      expect(cadence.onRoundCompleted(), isTrue, reason: 'round ${i + 1}');
    }
  });

  test('with everyNRounds 3 an ad is due after every third round', () {
    final cadence = AdCadence(everyNRounds: 3);
    final due = [for (var i = 0; i < 7; i++) cadence.onRoundCompleted()];
    expect(due, [false, false, true, false, false, true, false]);
  });

  test('every ad-free-eligible cadence is independent per instance', () {
    final a = AdCadence(everyNRounds: 2);
    final b = AdCadence(everyNRounds: 2);
    expect(a.onRoundCompleted(), isFalse);
    expect(b.onRoundCompleted(), isFalse);
    expect(a.onRoundCompleted(), isTrue);
    expect(b.onRoundCompleted(), isTrue);
  });
}
