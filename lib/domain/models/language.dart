enum Language { de, en, ru, fr, it, es }

extension LanguageCode on Language {
  String get code => switch (this) {
        Language.de => 'de',
        Language.en => 'en',
        Language.ru => 'ru',
        Language.fr => 'fr',
        Language.it => 'it',
        Language.es => 'es',
      };

  /// Unicode regional-indicator flag shown next to the language name.
  String get flagEmoji => switch (this) {
        Language.de => '🇩🇪',
        Language.en => '🇬🇧',
        Language.ru => '🇷🇺',
        Language.fr => '🇫🇷',
        Language.it => '🇮🇹',
        Language.es => '🇪🇸',
      };

  static Language fromCode(String code) => switch (code) {
        'de' => Language.de,
        'ru' => Language.ru,
        'fr' => Language.fr,
        'it' => Language.it,
        'es' => Language.es,
        _ => Language.en,
      };
}
