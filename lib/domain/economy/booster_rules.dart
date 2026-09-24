import 'dart:math';

import '../models/letter_state.dart';
import '../models/round.dart';

class HintResult {
  final int position; // 0-based index
  final String letter;
  const HintResult({required this.position, required this.letter});
}

/// Computes booster effects on a round. Coin cost/affordability is handled
/// by [CoinLedger] separately; this class only decides *what* a booster reveals.
class BoosterRules {
  const BoosterRules();

  /// Reveals a random letter position that the player has not already
  /// solved (i.e. no previous guess marked it as "correct") and has not
  /// already been hinted in this round.
  HintResult revealHint(Round round, {Random? random}) {
    final solved = <int>{...round.revealedHints.keys};
    for (final guess in round.guesses) {
      for (var i = 0; i < guess.evaluation.length; i++) {
        if (guess.evaluation[i].state == LetterState.correct) solved.add(i);
      }
    }
    final unsolved = [
      for (var i = 0; i < round.solutionWord.length; i++)
        if (!solved.contains(i)) i,
    ];
    if (unsolved.isEmpty) {
      throw StateError('No unsolved letters left to hint.');
    }
    final rng = random ?? Random();
    final position = unsolved[rng.nextInt(unsolved.length)];
    return HintResult(position: position, letter: round.solutionWord[position]);
  }

  /// Returns true if there are unsolved letter positions left to hint.
  bool canHint(Round round) {
    final solved = <int>{...round.revealedHints.keys};
    for (final guess in round.guesses) {
      for (var i = 0; i < guess.evaluation.length; i++) {
        if (guess.evaluation[i].state == LetterState.correct) solved.add(i);
      }
    }
    return solved.length < round.solutionWord.length;
  }

  /// Returns true if there are letters/digits left in the alphabet that are not in the
  /// solution and not yet disabled.
  bool canStrikeOut(Round round, {required List<String> alphabet}) {
    final solutionLetters = round.solutionWord.toUpperCase().split('').toSet();
    return alphabet
        .map((l) => l.toUpperCase())
        .any((l) => !solutionLetters.contains(l) && !round.disabledLetters.contains(l));
  }

  /// Picks a letter that does not appear in the solution and is not yet
  /// disabled, to strike out on the virtual keyboard.
  String? pickLetterToStrikeOut(Round round, {required List<String> alphabet, Random? random}) {
    final solutionLetters = round.solutionWord.toUpperCase().split('').toSet();
    final candidates = alphabet
        .map((l) => l.toUpperCase())
        .where((l) => !solutionLetters.contains(l))
        .where((l) => !round.disabledLetters.contains(l))
        .toList();
    if (candidates.isEmpty) return null;
    final rng = random ?? Random();
    return candidates[rng.nextInt(candidates.length)];
  }
}
