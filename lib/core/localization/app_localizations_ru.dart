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

  @override
  String get subBenefitNoAds => 'Никакой рекламы';

  @override
  String get subBenefitBonus => 'Ежедневный бонус монет без видео';

  @override
  String get subBenefitDiscount => 'Скидки на подсказки';

  @override
  String get planMonthly => 'Ежемесячно';

  @override
  String get planYearly => 'Ежегодно';

  @override
  String get subscriptionActive => 'Активна';

  @override
  String subscriptionRenews(Object date) {
    return 'Продлится $date';
  }

  @override
  String get guessDistribution => 'Распределение попыток';

  @override
  String get resultWon => 'ОТЛИЧНО!';

  @override
  String get resultLost => 'Почти!';

  @override
  String get resultWonSub => 'Вы разгадали слово!';

  @override
  String get resultLostSub => 'В следующий раз получится.';

  @override
  String get solutionLabel => 'Загаданное слово';

  @override
  String get attemptsLabel => 'Попытки';

  @override
  String get streakLabel => 'Серия';

  @override
  String get shareResult => 'Поделиться';

  @override
  String get copiedToClipboard => 'Результат скопирован!';

  @override
  String get ok => 'OK';

  @override
  String coinsEarned(Object coins) {
    return '$coins монет';
  }

  @override
  String get continueTitleStreak => 'Потерять серию?';

  @override
  String continueBodyStreak(int streak) {
    return 'Вы действительно хотите потерять серию из $streak?';
  }

  @override
  String get continueTitleNoStreak => 'Ещё одна попытка?';

  @override
  String get continueBodyNoStreak => 'Спасите раунд дополнительной попыткой.';

  @override
  String get continueBuy => 'Доп. попытка';

  @override
  String get continueDeclineStreak => 'Потерять серию';

  @override
  String get continueDeclineNoStreak => 'Сдаться';

  @override
  String get continueGetCoins => 'Получить монеты';
}
