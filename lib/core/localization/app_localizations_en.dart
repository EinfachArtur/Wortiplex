// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wortiplex';

  @override
  String get menuClassic => 'Classic';

  @override
  String get menuDaily => 'Daily Puzzle';

  @override
  String get menuWordFever => 'Word Fever';

  @override
  String get menuSecretWord => 'Secret Word';

  @override
  String get menuTogether => 'Wortiplex Together';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get coins => 'Coins';

  @override
  String get shop => 'Shop';

  @override
  String get settings => 'Settings';

  @override
  String get statistics => 'Statistics';

  @override
  String get howToPlay => 'How to play';

  @override
  String get language => 'Language';

  @override
  String get hint => 'Hint';

  @override
  String get strikeOutLetter => 'Strike out letter';

  @override
  String get skip => 'Skip';

  @override
  String get newGame => 'New game';

  @override
  String get youWon => 'You won!';

  @override
  String get youLost => 'Out of tries';

  @override
  String solutionWas(Object word) {
    return 'The word was $word';
  }

  @override
  String get notEnoughLetters => 'Not enough letters';

  @override
  String get notInWordList => 'Not in word list';

  @override
  String get notEnoughCoins => 'Not enough coins';

  @override
  String get watchAdFor20Coins => 'Watch an ad for 20 coins';

  @override
  String get removeAds => 'Remove ads';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get subscriptionTitle => 'Wortiplex+';

  @override
  String get gamesPlayed => 'Played';

  @override
  String get winRate => 'Win %';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get maxStreak => 'Max streak';

  @override
  String get play => 'Play';

  @override
  String get mostPopular => 'Most popular';

  @override
  String get bestValue => 'Best value';

  @override
  String get dailyAlreadyPlayed =>
      'You already solved today\'s puzzle. Come back tomorrow!';

  @override
  String get dailyLoginTitle => 'Daily gift';

  @override
  String dailyLoginClaim(Object coins) {
    return 'Claim $coins coins';
  }

  @override
  String get dailyLoginClaimed => 'Come back tomorrow for more';

  @override
  String get spinWheelTitle => 'Spin the wheel';

  @override
  String get spinWheelAction => 'Spin now';

  @override
  String get spinWheelUsed => 'Come back tomorrow to spin again';

  @override
  String spinWheelWon(Object coins) {
    return 'You won $coins coins!';
  }

  @override
  String get score => 'Score';

  @override
  String get submit => 'Submit';

  @override
  String get notAWord => 'Not a word';

  @override
  String get spinButton => 'SPIN';

  @override
  String get free => 'FREE';

  @override
  String get claim => 'CLAIM';

  @override
  String get prizeHint => 'Hint';

  @override
  String get prizeStrikeout => 'Strike-out';

  @override
  String get prizeSkip => 'Skip';

  @override
  String get prizeSpin => 'Spin';

  @override
  String get tabPuzzles => 'Puzzles';

  @override
  String get tabTrophies => 'Trophies';

  @override
  String get monthlyPrizes => 'Monthly goals';

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wins',
      one: '$count win',
    );
    return '$_temp0';
  }

  @override
  String playDate(String date) {
    return 'PLAY $date';
  }

  @override
  String get puzzleLocked => 'This puzzle is not available yet';

  @override
  String get prizeClaimed => 'Prize claimed!';
}
