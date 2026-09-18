import '../models/letter_state.dart';

/// Evaluates a guess against a solution using standard Wordle rules,
/// including correct handling of duplicate letters.
class GuessEvaluator {
  const GuessEvaluator();

  List<LetterGuess> evaluate({required String guess, required String solution}) {
    assert(guess.length == solution.length);

    final guessLetters = guess.toUpperCase().split('');
    final solutionLetters = solution.toUpperCase().split('');
    final states = List<LetterState>.filled(guessLetters.length, LetterState.absent);

    // Pool of solution letters still available to be matched as "present".
    final remaining = <String, int>{};
    for (final l in solutionLetters) {
      remaining[l] = (remaining[l] ?? 0) + 1;
    }

    // Pass 1: exact matches.
    for (var i = 0; i < guessLetters.length; i++) {
      if (guessLetters[i] == solutionLetters[i]) {
        states[i] = LetterState.correct;
        remaining[guessLetters[i]] = remaining[guessLetters[i]]! - 1;
      }
    }

    // Pass 2: present but wrong position.
    for (var i = 0; i < guessLetters.length; i++) {
      if (states[i] == LetterState.correct) continue;
      final letter = guessLetters[i];
      if ((remaining[letter] ?? 0) > 0) {
        states[i] = LetterState.present;
        remaining[letter] = remaining[letter]! - 1;
      } else {
        states[i] = LetterState.absent;
      }
    }

    return [
      for (var i = 0; i < guessLetters.length; i++) LetterGuess(guessLetters[i], states[i]),
    ];
  }

  bool isWinningGuess(List<LetterGuess> evaluation) =>
      evaluation.every((g) => g.state == LetterState.correct);
}
