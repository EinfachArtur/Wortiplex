import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/game/date_guess_validator.dart';

void main() {
  const validator = DateGuessValidator();

  test('accepts real calendar dates', () {
    expect(validator.isValid('02081861'), isTrue); // 02.08.1861
    expect(validator.isValid('01012000'), isTrue); // New Year's Day
    expect(validator.isValid('31122099'), isTrue); // 31 December is always valid
    expect(validator.isValid('11111111'), isTrue); // day 11, month 11, year 1111
  });

  test('handles leap years correctly', () {
    expect(validator.isValid('29022000'), isTrue); // 2000 is a leap year
    expect(validator.isValid('29021600'), isTrue); // divisible by 400
    expect(validator.isValid('29022024'), isTrue); // divisible by 4, not by 100
    expect(validator.isValid('29021900'), isFalse); // divisible by 100, not by 400
    expect(validator.isValid('29022023'), isFalse); // not a leap year
  });

  test('rejects an impossible day for the given month', () {
    expect(validator.isValid('30022024'), isFalse); // no 30 February, leap or not
    expect(validator.isValid('31042024'), isFalse); // April has 30 days
    expect(validator.isValid('31062024'), isFalse); // June has 30 days
  });

  test('rejects an out-of-range month or a zero day', () {
    expect(validator.isValid('01132024'), isFalse); // month 13
    expect(validator.isValid('01002024'), isFalse); // month 0
    expect(validator.isValid('00012024'), isFalse); // day 0
  });

  test('rejects anything that is not exactly 8 digits', () {
    expect(validator.isValid('0208186'), isFalse);
    expect(validator.isValid('020818611'), isFalse);
    expect(validator.isValid('0208186A'), isFalse);
    expect(validator.isValid(''), isFalse);
  });
}
