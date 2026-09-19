import '../../core/config/word_fever_config.dart';

/// State of one Word Fever run: a countdown that is topped up by every solved
/// word, plus the score. Pure and immutable so it can be tested without a UI.
class WordFeverRun {
  final int secondsLeft;
  final int solved;
  final int failed;
  final int score;

  /// Words solved in a row; a failed or skipped word resets it.
  final int combo;

  const WordFeverRun({
    required this.secondsLeft,
    this.solved = 0,
    this.failed = 0,
    this.score = 0,
    this.combo = 0,
  });

  factory WordFeverRun.start() => const WordFeverRun(secondsLeft: WordFeverConfig.startSeconds);

  bool get isOver => secondsLeft <= 0;

  WordFeverRun tick() => secondsLeft <= 0 ? this : _copy(secondsLeft: secondsLeft - 1);

  /// Points a word would earn right now if solved with [attemptsLeft] tries to spare.
  int pointsFor(int attemptsLeft) {
    final comboSteps = combo < WordFeverConfig.maxComboBonusSteps ? combo : WordFeverConfig.maxComboBonusSteps;
    return WordFeverConfig.basePoints +
        WordFeverConfig.pointsPerAttemptLeft * (attemptsLeft < 0 ? 0 : attemptsLeft) +
        WordFeverConfig.pointsPerCombo * comboSteps;
  }

  WordFeverRun withSolved({required int attemptsLeft}) => _copy(
        secondsLeft: secondsLeft + WordFeverConfig.solveBonusSeconds,
        solved: solved + 1,
        score: score + pointsFor(attemptsLeft),
        combo: combo + 1,
      );

  WordFeverRun withFailed() => _copy(failed: failed + 1, combo: 0);

  WordFeverRun _copy({int? secondsLeft, int? solved, int? failed, int? score, int? combo}) => WordFeverRun(
        secondsLeft: secondsLeft ?? this.secondsLeft,
        solved: solved ?? this.solved,
        failed: failed ?? this.failed,
        score: score ?? this.score,
        combo: combo ?? this.combo,
      );
}
