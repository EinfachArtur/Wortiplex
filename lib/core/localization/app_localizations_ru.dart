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

  @override
  String get dailyLoginTitle => 'Подарок дня';

  @override
  String dailyLoginClaim(Object coins) {
    return 'Забрать $coins монет';
  }

  @override
  String get dailyLoginClaimed => 'Возвращайтесь завтра за новым подарком';

  @override
  String get spinWheelTitle => 'Колесо удачи';

  @override
  String get spinWheelAction => 'Крутить';

  @override
  String get spinWheelUsed => 'Возвращайтесь завтра, чтобы крутить снова';

  @override
  String spinWheelWon(Object coins) {
    return 'Вы выиграли $coins монет!';
  }

  @override
  String get score => 'Серия';

  @override
  String get submit => 'Ввод';

  @override
  String get notAWord => 'Нет такого слова';

  @override
  String get spinButton => 'КРУТИТЬ';

  @override
  String get free => 'БЕСПЛАТНО';

  @override
  String get claim => 'ЗАБРАТЬ';

  @override
  String get prizeHint => 'Подсказка';

  @override
  String get prizeStrikeout => 'Вычеркнуть';

  @override
  String get prizeSkip => 'Пропуск';

  @override
  String get prizeSpin => 'Вращение';

  @override
  String get tabPuzzles => 'Задачи';

  @override
  String get tabTrophies => 'Трофеи';

  @override
  String get monthlyPrizes => 'Цели месяца';

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count побед',
      many: '$count побед',
      few: '$count победы',
      one: '$count победа',
    );
    return '$_temp0';
  }

  @override
  String playDate(String date) {
    return 'ИГРАТЬ $date';
  }

  @override
  String get puzzleLocked => 'Эта задача пока недоступна';

  @override
  String get prizeClaimed => 'Приз получен!';
}
