import 'game_mode.dart';
import 'language.dart';
import 'letter_state.dart';

class Guess {
  final String word;
  final List<LetterGuess> evaluation;

  const Guess({required this.word, required this.evaluation});

  Map<String, dynamic> toMap() => {
    'word': word,
    'evaluation': evaluation.map((e) => e.toMap()).toList(),
  };

  factory Guess.fromMap(Map map) => Guess(
    word: map['word'] as String,
    evaluation: ((map['evaluation'] as List?) ?? [])
        .map((e) => LetterGuess.fromMap(e as Map))
        .toList(),
  );
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
  final Map<int, String> revealedHints;

  /// How many bought extra attempts this round already contains.
  final int extraAttempts;

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
    this.revealedHints = const {},
    this.extraAttempts = 0,
  });

  bool get isFinished => result != RoundResult.inProgress;
  int get attemptsUsed => guesses.length;
  int get attemptsLeft => maxAttempts - attemptsUsed;

  Round copyWith({
    List<Guess>? guesses,
    RoundResult? result,
    DateTime? completedAt,
    Set<String>? disabledLetters,
    Map<int, String>? revealedHints,
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
      revealedHints: revealedHints ?? this.revealedHints,
      extraAttempts: extraAttempts,
    );
  }

  /// Re-opens a lost round with one more attempt. Only lost rounds can be
  /// continued; anything else is returned unchanged.
  Round withExtraAttempt() {
    if (result != RoundResult.lost) return this;
    return Round(
      id: id,
      mode: mode,
      language: language,
      solutionWord: solutionWord,
      startedAt: startedAt,
      maxAttempts: maxAttempts + 1,
      guesses: guesses,
      result: RoundResult.inProgress,
      completedAt: null,
      disabledLetters: disabledLetters,
      revealedHints: revealedHints,
      extraAttempts: extraAttempts + 1,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'mode': mode.name,
    'language': language.code,
    'solutionWord': solutionWord,
    'maxAttempts': maxAttempts,
    'guesses': guesses.map((g) => g.toMap()).toList(),
    'result': result.name,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'disabledLetters': disabledLetters.toList(),
    'revealedHints': revealedHints.map((k, v) => MapEntry(k.toString(), v)),
    'extraAttempts': extraAttempts,
  };

  factory Round.fromMap(Map map) {
    final hintsRaw = (map['revealedHints'] as Map?) ?? {};
    final hints = <int, String>{};
    hintsRaw.forEach((k, v) {
      hints[int.parse(k.toString())] = v.toString();
    });

    return Round(
      id: map['id'] as String,
      mode: GameMode.values.byName(map['mode'] as String),
      language: LanguageCode.fromCode(map['language'] as String? ?? 'de'),
      solutionWord: map['solutionWord'] as String,
      maxAttempts: (map['maxAttempts'] as num?)?.toInt() ?? 6,
      guesses: ((map['guesses'] as List?) ?? [])
          .map((g) => Guess.fromMap(g as Map))
          .toList(),
      result: RoundResult.values.byName(map['result'] as String),
      startedAt: DateTime.parse(map['startedAt'] as String),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
      disabledLetters: ((map['disabledLetters'] as List?) ?? []).map((e) => e.toString()).toSet(),
      revealedHints: hints,
      extraAttempts: (map['extraAttempts'] as num?)?.toInt() ?? 0,
    );
  }
}
