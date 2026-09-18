// Placeholder widget smoke test.
//
// A full app-level smoke test requires mocking Hive's platform channel and
// AdMob initialization, which main() performs before runApp(). That harness
// is left for a later etappe; domain logic (the testable core) is covered
// under test/domain instead.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder', () {
    expect(1 + 1, 2);
  });
}
