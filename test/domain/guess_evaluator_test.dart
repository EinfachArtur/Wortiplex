import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/game/guess_evaluator.dart';
import 'package:wortiplex/domain/models/letter_state.dart';

void main() {
  const evaluator = GuessEvaluator();

  test('marks all letters correct on an exact match', () {
    final result = evaluator.evaluate(guess: 'APPLE', solution: 'APPLE');
    expect(result.every((g) => g.state == LetterState.correct), isTrue);
    expect(evaluator.isWinningGuess(result), isTrue);
  });

  test('marks letters absent when not in solution', () {
    final result = evaluator.evaluate(guess: 'ABCDE', solution: 'FGHIJ');
    expect(result.every((g) => g.state == LetterState.absent), isTrue);
  });

  test('handles duplicate letters without over-counting present matches', () {
    // Solution has one "L", guess has two -> only one should be marked present/correct.
    final result = evaluator.evaluate(guess: 'LLAMA', solution: 'ALARM');
    final lStates = [result[0].state, result[1].state];
    final presentOrCorrectCount = lStates.where(
      (s) => s == LetterState.present || s == LetterState.correct,
    ).length;
    expect(presentOrCorrectCount, 1);
  });

  test('prioritises correct position over present when letter appears twice', () {
    final result = evaluator.evaluate(guess: 'ERROR', solution: 'ROBOT');
    // solution ROBOT: R(0) O(1) B(2) O(3) T(4)
    // guess    ERROR: E(0) R(1) R(2) O(3) R(4)
    expect(result[3].state, LetterState.correct); // O at index 3 matches
  });
}
