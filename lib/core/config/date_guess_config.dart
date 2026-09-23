/// Tunable rules of the "date guess" mode: a Wordle for calendar dates
/// (DDMMYYYY), where a target date is drawn from a plausible year range.
class DateGuessConfig {
  const DateGuessConfig._();

  static const int minYear = 1900;

  /// Never in the future: today's year.
  static int get maxYear => DateTime.now().year;
}
