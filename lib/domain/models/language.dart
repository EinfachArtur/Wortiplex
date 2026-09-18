enum Language { de, en, ru }

extension LanguageCode on Language {
  String get code => switch (this) {
        Language.de => 'de',
        Language.en => 'en',
        Language.ru => 'ru',
      };

  static Language fromCode(String code) => switch (code) {
        'de' => Language.de,
        'ru' => Language.ru,
        _ => Language.en,
      };
}
