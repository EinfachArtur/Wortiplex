import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/models/language.dart';
import 'package:wortiplex/services/daily_puzzle_service.dart';

void main() {
  const service = DailyPuzzleService();
  final pool = [for (var i = 0; i < 1000; i++) 'W$i'];

  String solution(DateTime d) => service.solutionFor(language: Language.de, solutionPool: pool, date: d);

  test('a local-midnight date and the same date at noon give the same puzzle', () {
    expect(solution(DateTime(2026, 9, 18)), solution(DateTime(2026, 9, 18, 12)));
    expect(solution(DateTime(2026, 9, 18, 23, 59)), solution(DateTime(2026, 9, 18)));
  });

  test('consecutive days give consecutive pool entries', () {
    final a = pool.indexOf(solution(DateTime(2026, 9, 18)));
    final b = pool.indexOf(solution(DateTime(2026, 9, 19)));
    expect(b, (a + 1) % pool.length);
  });

  test('the puzzle does not depend on the timezone of the DateTime', () {
    expect(solution(DateTime(2026, 9, 18)), solution(DateTime.utc(2026, 9, 18)));
  });
}
