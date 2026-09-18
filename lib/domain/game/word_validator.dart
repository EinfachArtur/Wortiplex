/// Validates that a candidate guess is a real word for the active language.
/// Solutions are always accepted as valid guesses even if the broader
/// guess dictionary for a language is still sparse (starter word lists).
class WordValidator {
  final Set<String> _validWords;

  WordValidator({required Set<String> solutions, required Set<String> validGuesses})
      : _validWords = {
          ...solutions.map((w) => w.toUpperCase()),
          ...validGuesses.map((w) => w.toUpperCase()),
        };

  bool isValid(String word) => _validWords.contains(word.toUpperCase());
}
