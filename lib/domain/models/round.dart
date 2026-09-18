import 'game_mode.dart';
import 'language.dart';
import 'letter_state.dart';

class Guess {
  final String word;
  final List<LetterGuess> evaluation;

  const Guess({required this.word, required this.evaluation});
}

class Round {
  final String id;
  final GameMode mode;
  final Language language;
  final String solutionWord;
  final int maxAttempts;
  final List<Guess> guesses;
  final RoundResult result;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Set<String> disabledLetters;

  const Round({
    required this.id,
    required this.mode,
    required this.language,
    required this.solutionWord,
    required this.startedAt,
    this.maxAttempts = 6,
    this.guesses = const [],
    this.result = RoundResult.inProgress,
    this.completedAt,
    this.disabledLetters = const {},
  });

  bool get isFinished => result != RoundResult.inProgress;
  int get attemptsUsed => guesses.length;
  int get attemptsLeft => maxAttempts - attemptsUsed;

  Round copyWith({
    List<Guess>? guesses,
    RoundResult? result,
    DateTime? completedAt,
    Set<String>? disabledLetters,
  }) {
    return Round(
      id: id,
      mode: mode,
      language: language,
      solutionWord: solutionWord,
      startedAt: startedAt,
      maxAttempts: maxAttempts,
      guesses: guesses ?? this.guesses,
      result: result ?? this.result,
      completedAt: completedAt ?? this.completedAt,
      disabledLetters: disabledLetters ?? this.disabledLetters,
    );
  }
}
