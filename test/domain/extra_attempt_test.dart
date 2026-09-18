import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/game/game_session.dart';
import 'package:wortiplex/domain/game/word_validator.dart';
import 'package:wortiplex/domain/models/game_mode.dart';
import 'package:wortiplex/domain/models/language.dart';
import 'package:wortiplex/domain/models/round.dart';

void main() {
  final session = GameSession(
    validator: WordValidator(solutions: {'APPLE'}, validGuesses: {'ABOUT', 'ALERT'}),
  );

  Round lostRound() {
    var round = Round(
      id: 'r',
      mode: GameMode.classic,
      language: Language.en,
      solutionWord: 'APPLE',
      startedAt: DateTime(2024),
    );
    for (var i = 0; i < 6; i++) {
      round = (session.submitGuess(round, 'ABOUT') as GuessAccepted).round;
    }
    return round;
  }

  test('a round is lost after six wrong guesses', () {
    final round = lostRound();
    expect(round.result, RoundResult.lost);
    expect(round.attemptsLeft, 0);
  });

  test('an extra attempt re-opens a lost round with exactly one more guess', () {
    final round = lostRound().withExtraAttempt();
    expect(round.result, RoundResult.inProgress);
    expect(round.isFinished, isFalse);
    expect(round.maxAttempts, 7);
    expect(round.attemptsLeft, 1);
    expect(round.extraAttempts, 1);
    expect(round.guesses.length, 6);
  });

  test('the extra attempt can win the round', () {
    final round = lostRound().withExtraAttempt();
    final outcome = session.submitGuess(round, 'APPLE') as GuessAccepted;
    expect(outcome.round.result, RoundResult.won);
    expect(outcome.round.attemptsUsed, 7);
  });

  test('a wrong extra guess loses the round again', () {
    final round = lostRound().withExtraAttempt();
    final outcome = session.submitGuess(round, 'ALERT') as GuessAccepted;
    expect(outcome.round.result, RoundResult.lost);
    expect(outcome.round.maxAttempts, 7);
  });

  test('only lost rounds can be continued', () {
    final fresh = Round(
      id: 'r',
      mode: GameMode.classic,
      language: Language.en,
      solutionWord: 'APPLE',
      startedAt: DateTime(2024),
    );
    expect(identical(fresh.withExtraAttempt(), fresh), isTrue);

    final won = (session.submitGuess(fresh, 'APPLE') as GuessAccepted).round;
    expect(identical(won.withExtraAttempt(), won), isTrue);
  });
}
