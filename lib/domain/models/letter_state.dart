enum LetterState { unknown, absent, present, correct }

class LetterGuess {
  final String letter;
  final LetterState state;

  const LetterGuess(this.letter, this.state);
}
