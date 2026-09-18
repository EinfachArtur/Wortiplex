import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/economy/monthly_prizes.dart';
import 'package:wortiplex/domain/models/daily_history.dart';
import 'package:wortiplex/domain/models/language.dart';

void main() {
  test('records results per language and date', () {
    var h = const DailyHistory();
    h = h.withResult(Language.de, DateTime(2026, 9, 3), won: true);
    h = h.withResult(Language.de, DateTime(2026, 9, 4), won: false);

    expect(h.resultFor(Language.de, DateTime(2026, 9, 3)), isTrue);
    expect(h.resultFor(Language.de, DateTime(2026, 9, 4)), isFalse);
    expect(h.resultFor(Language.de, DateTime(2026, 9, 5)), isNull);
    expect(h.resultFor(Language.en, DateTime(2026, 9, 3)), isNull);
    expect(h.hasPlayed(Language.de, DateTime(2026, 9, 4)), isTrue);
  });

  test('counts only wins of the requested month and language', () {
    var h = const DailyHistory();
    for (final d in [1, 2, 3]) {
      h = h.withResult(Language.de, DateTime(2026, 9, d), won: true);
    }
    h = h.withResult(Language.de, DateTime(2026, 9, 4), won: false);
    h = h.withResult(Language.de, DateTime(2026, 8, 31), won: true);
    h = h.withResult(Language.en, DateTime(2026, 9, 1), won: true);

    expect(h.winsInMonth(Language.de, 2026, 9), 3);
    expect(h.winsInMonth(Language.de, 2026, 8), 1);
    expect(h.winsInMonth(Language.en, 2026, 9), 1);
  });

  test('survives a map round trip', () {
    final h = const DailyHistory().withResult(Language.ru, DateTime(2026, 1, 9), won: true);
    final restored = DailyHistory.fromMap(h.toMap());
    expect(restored.resultFor(Language.ru, DateTime(2026, 1, 9)), isTrue);
  });

  group('MonthlyPrizes', () {
    const prizes = MonthlyPrizes([
      MonthlyPrizeTier(3, 50),
      MonthlyPrizeTier(10, 150),
      MonthlyPrizeTier(30, 500),
    ]);

    test('tiers are reached at their win counts', () {
      expect(prizes.isReached(0, 2), isFalse);
      expect(prizes.isReached(0, 3), isTrue);
      expect(prizes.isReached(1, 9), isFalse);
      expect(prizes.isReached(2, 30), isTrue);
    });

    test('progress knob travels marker to marker and stops at the last one', () {
      expect(prizes.markerPosition(0), closeTo(1 / 6, 1e-9));
      expect(prizes.markerPosition(2), closeTo(5 / 6, 1e-9));
      expect(prizes.progress(0), 0);
      expect(prizes.progress(3), closeTo(1 / 6, 1e-9));
      expect(prizes.progress(10), closeTo(3 / 6, 1e-9));
      expect(prizes.progress(30), closeTo(5 / 6, 1e-9));
      expect(prizes.progress(99), closeTo(5 / 6, 1e-9));
      expect(prizes.progress(1), closeTo(1 / 18, 1e-9));
    });

    test('claim keys are unique per language, month and tier', () {
      expect(MonthlyPrizes.claimKey('de', 2026, 9, 0), 'de_2026-09_0');
      expect(MonthlyPrizes.claimKey('de', 2026, 9, 1) == MonthlyPrizes.claimKey('en', 2026, 9, 1), isFalse);
    });
  });
}
