enum LetterState { unknown, absent, present, correct }

class LetterGuess {
  final String letter;
  final LetterState state;

  const LetterGuess(this.letter, this.state);

  Map<String, dynamic> toMap() => {
    'letter': letter,
    'state': state.name,
  };

  factory LetterGuess.fromMap(Map map) => LetterGuess(
    map['letter'] as String,
    LetterState.values.byName(map['state'] as String),
  );
}
