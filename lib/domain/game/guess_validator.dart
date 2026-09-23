/// Decides whether a candidate guess may be submitted at all, independent of
/// whether it turns out to match the solution. [WordValidator] implements
/// this against a dictionary; [DateGuessValidator] implements it against the
/// calendar.
abstract class GuessValidator {
  bool isValid(String candidate);
}
