// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Wortiplex';

  @override
  String get menuClassic => 'Классика';

  @override
  String get menuDaily => 'Задача дня';

  @override
  String get menuWordFever => 'Word Fever';

  @override
  String get menuSecretWord => 'Секретное слово';

  @override
  String get menuTogether => 'Wortiplex Together';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get coins => 'Монеты';

  @override
  String get shop => 'Магазин';

  @override
  String get settings => 'Настройки';

  @override
  String get statistics => 'Статистика';

  @override
  String get howToPlay => 'Правила игры';

  @override
  String get language => 'Язык';

  @override
  String get hint => 'Подсказка';

  @override
  String get strikeOutLetter => 'Вычеркнуть букву';

  @override
  String get skip => 'Пропустить';

  @override
  String get newGame => 'Новая игра';

  @override
  String get youWon => 'Вы выиграли!';

  @override
  String get youLost => 'Попытки закончились';

  @override
  String solutionWas(Object word) {
    return 'Загаданное слово: $word';
  }

  @override
  String get notEnoughLetters => 'Недостаточно букв';

  @override
  String get notInWordList => 'Нет в списке слов';

  @override
  String get notEnoughCoins => 'Недостаточно монет';

  @override
  String get watchAdFor20Coins => 'Посмотреть рекламу за 20 монет';

  @override
  String get removeAds => 'Отключить рекламу';

  @override
  String get restorePurchases => 'Восстановить покупки';

  @override
  String get subscriptionTitle => 'Wortiplex+';

  @override
  String get gamesPlayed => 'Сыграно';

  @override
  String get winRate => 'Побед, %';

  @override
  String get currentStreak => 'Текущая серия';

  @override
  String get maxStreak => 'Лучшая серия';

  @override
  String get play => 'Играть';

  @override
  String get mostPopular => 'Популярно';

  @override
  String get bestValue => 'Выгодно';

  @override
  String get dailyAlreadyPlayed =>
      'Вы уже решили сегодняшнюю задачу. Возвращайтесь завтра!';
}
