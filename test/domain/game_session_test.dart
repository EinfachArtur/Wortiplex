import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/game/game_session.dart';
import 'package:wortiplex/domain/game/word_validator.dart';
import 'package:wortiplex/domain/models/game_mode.dart';
import 'package:wortiplex/domain/models/language.dart';
import 'package:wortiplex/domain/models/round.dart';

void main() {
  GameSession session() => GameSession(
        validator: WordValidator(
          solutions: {'APPLE'},
          validGuesses: {'ABOUT', 'ALERT'},
        ),
      );

  Round freshRound() => Round(
        id: 'r1',
        mode: GameMode.classic,
        language: Language.en,
        solutionWord: 'APPLE',
        startedAt: DateTime(2024),
      );

  test('rejects a word not in the dictionary', () {
    final outcome = session().submitGuess(freshRound(), 'ZZZZZ');
    expect(outcome, isA<GuessRejected>());
    expect((outcome as GuessRejected).reason, GuessRejectReason.notInDictionary);
  });

  test('accepts a valid guess and appends it to the round', () {
    final outcome = session().submitGuess(freshRound(), 'ABOUT');
    expect(outcome, isA<GuessAccepted>());
    final round = (outcome as GuessAccepted).round;
    expect(round.guesses.length, 1);
    expect(round.result, RoundResult.inProgress);
  });

  test('marks the round won on an exact solution match', () {
    final outcome = session().submitGuess(freshRound(), 'APPLE');
    final round = (outcome as GuessAccepted).round;
    expect(round.result, RoundResult.won);
    expect(round.isFinished, isTrue);
  });

  test('marks the round lost after max attempts without solving', () {
    var round = freshRound();
    final s = session();
    for (var i = 0; i < 6; i++) {
      final outcome = s.submitGuess(round, 'ABOUT') as GuessAccepted;
      round = outcome.round;
    }
    expect(round.result, RoundResult.lost);
  });

  test('rejects further guesses once the round is finished', () {
    final s = session();
    final won = (s.submitGuess(freshRound(), 'APPLE') as GuessAccepted).round;
    final outcome = s.submitGuess(won, 'ALERT');
    expect(outcome, isA<GuessRejected>());
    expect((outcome as GuessRejected).reason, GuessRejectReason.roundAlreadyFinished);
  });
}
