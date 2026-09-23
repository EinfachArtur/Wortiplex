import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/game/date_guess_service.dart';
import 'package:wortiplex/domain/game/date_guess_validator.dart';

void main() {
  test('every generated solution is a valid, 8-digit calendar date', () {
    final service = DateGuessService(minYear: 1900, maxYear: 2024);
    const validator = DateGuessValidator();
    final rng = Random(7);

    for (var i = 0; i < 500; i++) {
      final solution = service.randomSolution(random: rng);
      expect(solution.length, 8);
      expect(validator.isValid(solution), isTrue, reason: solution);
      final year = int.parse(solution.substring(4, 8));
      expect(year, inInclusiveRange(1900, 2024));
    }
  });

  test('defaults to a range ending at DateGuessConfig.maxYear (3000)', () {
    final service = DateGuessService(minYear: 2020);
    expect(service.maxYear, 3000);
  });

  test('a single-year range always returns that year', () {
    final service = DateGuessService(minYear: 2001, maxYear: 2001);
    final solution = service.randomSolution(random: Random(1));
    expect(solution.substring(4, 8), '2001');
  });
}
