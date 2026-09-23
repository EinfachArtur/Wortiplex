// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WortiPlex';

  @override
  String get menuClassic => 'Classic';

  @override
  String get menuDaily => 'Daily Puzzle';

  @override
  String get menuWordFever => 'Word Fever';

  @override
  String get menuSecretWord => 'Secret Word';

  @override
  String get menuTogether => 'WortiPlex Together';

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
  String get subscriptionTitle => 'WortiPlex+';

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

  @override
  String get subBenefitNoAds => 'No ads, ever';

  @override
  String get subBenefitBonus => 'Daily coin bonus, no video needed';

  @override
  String get subBenefitDiscount => 'Cheaper hints and strike-outs';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planYearly => 'Yearly';

  @override
  String get subscriptionActive => 'Active';

  @override
  String subscriptionRenews(Object date) {
    return 'Renews $date';
  }

  @override
  String get guessDistribution => 'Guess distribution';

  @override
  String get resultWon => 'GREAT!';

  @override
  String get resultLost => 'So close!';

  @override
  String get resultWonSub => 'You cracked the word!';

  @override
  String get resultLostSub => 'Better luck next round.';

  @override
  String get solutionLabel => 'Solution';

  @override
  String get attemptsLabel => 'Attempts';

  @override
  String get streakLabel => 'Streak';

  @override
  String get shareResult => 'Share result';

  @override
  String get copiedToClipboard => 'Result copied!';

  @override
  String get ok => 'OK';

  @override
  String coinsEarned(Object coins) {
    return '$coins coins';
  }

  @override
  String get continueTitleStreak => 'Lose your streak?';

  @override
  String continueBodyStreak(int streak) {
    return 'Do you really want to lose your streak of $streak?';
  }

  @override
  String get continueTitleNoStreak => 'One more try?';

  @override
  String get continueBodyNoStreak => 'Save this round with an extra attempt.';

  @override
  String get continueBuy => 'Extra attempt';

  @override
  String get continueDeclineStreak => 'Lose streak';

  @override
  String get continueDeclineNoStreak => 'Give up';

  @override
  String get continueGetCoins => 'Get coins';

  @override
  String get mainMenu => 'Main Menu';

  @override
  String get removeAdsPromptTitle => 'Fed up with ads?';

  @override
  String get removeAdsPromptBody =>
      'Play without interruptions between rounds.';

  @override
  String get removeAdsPromptOnce => 'One payment, yours forever';

  @override
  String removeAdsPromptBuy(String price) {
    return 'Go ad-free for $price';
  }

  @override
  String get removeAdsPromptLater => 'Maybe later';

  @override
  String get boosterHintTitle => 'Hint Booster';

  @override
  String get boosterStrikeoutTitle => 'Strike-out Booster';

  @override
  String get boosterSkipTitle => 'Skip Booster';

  @override
  String boosterGet(int count) {
    return 'Get $count';
  }

  @override
  String boosterOwned(int count) {
    return 'You have $count';
  }

  @override
  String get boosterBought => 'Purchased!';

  @override
  String wordFeverDesc(int seconds) {
    return 'Beat the clock: ${seconds}s';
  }

  @override
  String wordFeverBest(int score) {
    return 'Best: $score';
  }

  @override
  String get feverScore => 'Score';

  @override
  String get feverTimeUp => 'Time\'s up!';

  @override
  String get feverWordsSolved => 'Words solved';

  @override
  String get feverBestLabel => 'Best';

  @override
  String get feverNewBest => 'New record!';

  @override
  String get feverPlayAgain => 'Play again';

  @override
  String get playerId => 'Player ID';

  @override
  String get playerIdCopied => 'Player ID copied to clipboard';

  @override
  String get playerIdTapToCopy => 'Tap to copy';

  @override
  String get menuDateGuess => 'Date Guess';

  @override
  String dateGuessDesc(int minYear, int maxYear) {
    return 'Guess the date between $minYear and $maxYear';
  }

  @override
  String get dateFormatHint => 'DD MM YYYY';

  @override
  String get notAValidDate => 'Not a valid date';

  @override
  String get notEnoughDigits => 'Not enough digits';
}
