/// Tunable rules of the timed "Word Fever" mode.
class WordFeverConfig {
  const WordFeverConfig._();

  /// Length of a run, in seconds.
  static const int startSeconds = 90;

  /// Seconds added to the clock for every solved word.
  static const int solveBonusSeconds = 10;

  /// Points for a solved word, plus a bonus for every attempt left over and
  /// for every word solved in a row (capped).
  static const int basePoints = 100;
  static const int pointsPerAttemptLeft = 20;
  static const int pointsPerCombo = 10;
  static const int maxComboBonusSteps = 10;

  /// Coins paid out at the end of a run, per solved word.
  static const int coinsPerWord = 3;

  /// Below this many seconds the clock turns red.
  static const int lowTimeSeconds = 10;
}
