import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/domain/models/language.dart';

void main() {
  test('every language has a two-letter code and a flag emoji', () {
    for (final lang in Language.values) {
      expect(lang.code.length, 2);
      expect(lang.flagEmoji, isNotEmpty);
    }
    // Each language's code and flag are distinct from the others.
    expect(Language.values.map((l) => l.code).toSet().length, Language.values.length);
    expect(Language.values.map((l) => l.flagEmoji).toSet().length, Language.values.length);
  });

  test('fromCode round-trips every language and falls back to English', () {
    for (final lang in Language.values) {
      expect(LanguageCode.fromCode(lang.code), lang);
    }
    expect(LanguageCode.fromCode('xx'), Language.en);
  });

  test('the new languages are French, Italian and Spanish', () {
    expect(Language.values, containsAll([Language.fr, Language.it, Language.es]));
    expect(Language.fr.code, 'fr');
    expect(Language.it.code, 'it');
    expect(Language.es.code, 'es');
  });
}
