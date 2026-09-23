import 'guess_validator.dart';

/// Validates that a candidate guess is a real word for the active language.
/// Solutions are always accepted as valid guesses even if the broader
/// guess dictionary for a language is still sparse (starter word lists).
class WordValidator implements GuessValidator {
  final Set<String> _validWords;

  WordValidator({required Set<String> solutions, required Set<String> validGuesses})
    : _validWords = {...solutions.map((w) => w.toUpperCase()), ...validGuesses.map((w) => w.toUpperCase())};

  @override
  bool isValid(String word) => _validWords.contains(word.toUpperCase());
}
