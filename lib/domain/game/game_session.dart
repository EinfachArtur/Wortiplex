import '../models/game_mode.dart';
import '../models/letter_state.dart';
import '../models/round.dart';
import 'guess_evaluator.dart';
import 'word_validator.dart';

sealed class GuessOutcome {
  const GuessOutcome();
}

class GuessAccepted extends GuessOutcome {
  final Round round;
  const GuessAccepted(this.round);
}

class GuessRejected extends GuessOutcome {
  final GuessRejectReason reason;
  const GuessRejected(this.reason);
}

enum GuessRejectReason { wrongLength, notInDictionary, roundAlreadyFinished }

/// Orchestrates a single round: accepting guesses, evaluating them and
/// deciding when a round is won or lost. Pure domain logic, no I/O.
class GameSession {
  final GuessEvaluator _evaluator;
  final WordValidator _validator;

  GameSession({
    GuessEvaluator evaluator = const GuessEvaluator(),
    required WordValidator validator,
  })  : _evaluator = evaluator,
        _validator = validator;

  GuessOutcome submitGuess(Round round, String word) {
    if (round.isFinished) {
      return const GuessRejected(GuessRejectReason.roundAlreadyFinished);
    }
    if (word.length != round.solutionWord.length) {
      return const GuessRejected(GuessRejectReason.wrongLength);
    }
    if (!_validator.isValid(word)) {
      return const GuessRejected(GuessRejectReason.notInDictionary);
    }

    final evaluation = _evaluator.evaluate(guess: word, solution: round.solutionWord);
    final guesses = [...round.guesses, Guess(word: word.toUpperCase(), evaluation: evaluation)];

    final won = _evaluator.isWinningGuess(evaluation);
    final outOfAttempts = guesses.length >= round.maxAttempts;

    final result = won
        ? RoundResult.won
        : (outOfAttempts ? RoundResult.lost : RoundResult.inProgress);

    final updated = round.copyWith(
      guesses: guesses,
      result: result,
      completedAt: result != RoundResult.inProgress ? DateTime.now() : null,
    );

    return GuessAccepted(updated);
  }

  /// Keyboard letter states derived from all guesses so far (best state wins).
  Map<String, LetterState> keyboardStates(Round round) {
    final states = <String, LetterState>{};
    for (final guess in round.guesses) {
      for (final lg in guess.evaluation) {
        final current = states[lg.letter];
        if (current == null || _rank(lg.state) > _rank(current)) {
          states[lg.letter] = lg.state;
        }
      }
    }
    for (final letter in round.disabledLetters) {
      states.putIfAbsent(letter, () => LetterState.absent);
    }
    return states;
  }

  int _rank(LetterState s) => switch (s) {
        LetterState.unknown => 0,
        LetterState.absent => 1,
        LetterState.present => 2,
        LetterState.correct => 3,
      };
}
