import 'guess_validator.dart';

/// Validates that an 8-digit guess (DDMMYYYY) is a real calendar date. The
/// year itself is unrestricted (any 4-digit year is accepted, however
/// implausible), so a guess like "11111111" is valid as long as day/month/
/// leap-year rules hold — only [DateGuessService] restricts which years a
/// *solution* is drawn from.
class DateGuessValidator implements GuessValidator {
  const DateGuessValidator();

  static const _daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  @override
  bool isValid(String candidate) {
    if (candidate.length != 8 || int.tryParse(candidate) == null) return false;
    final day = int.parse(candidate.substring(0, 2));
    final month = int.parse(candidate.substring(2, 4));
    final year = int.parse(candidate.substring(4, 8));
    if (month < 1 || month > 12) return false;
    if (day < 1) return false;
    return day <= daysInMonth(month, year);
  }

  bool isLeapYear(int year) => (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  /// 1-indexed month (1 = January).
  int daysInMonth(int month, int year) => (month == 2 && isLeapYear(year)) ? 29 : _daysInMonth[month - 1];
}
