// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Wortiplex';

  @override
  String get menuClassic => 'Classic';

  @override
  String get menuDaily => 'Tagesrätsel';

  @override
  String get menuWordFever => 'Word Fever';

  @override
  String get menuSecretWord => 'Geheimwort';

  @override
  String get menuTogether => 'Wortiplex Together';

  @override
  String get comingSoon => 'Demnächst verfügbar';

  @override
  String get coins => 'Münzen';

  @override
  String get shop => 'Shop';

  @override
  String get settings => 'Einstellungen';

  @override
  String get statistics => 'Statistik';

  @override
  String get howToPlay => 'Spielregeln';

  @override
  String get language => 'Sprache';

  @override
  String get hint => 'Tipp';

  @override
  String get strikeOutLetter => 'Buchstabe streichen';

  @override
  String get skip => 'Überspringen';

  @override
  String get newGame => 'Neues Spiel';

  @override
  String get youWon => 'Gewonnen!';

  @override
  String get youLost => 'Keine Versuche mehr';

  @override
  String solutionWas(Object word) {
    return 'Das Wort war $word';
  }

  @override
  String get notEnoughLetters => 'Zu wenige Buchstaben';

  @override
  String get notInWordList => 'Nicht in der Wortliste';

  @override
  String get notEnoughCoins => 'Nicht genug Münzen';

  @override
  String get watchAdFor20Coins => 'Werbevideo für 20 Münzen ansehen';

  @override
  String get removeAds => 'Werbung entfernen';

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get subscriptionTitle => 'Wortiplex+';

  @override
  String get gamesPlayed => 'Gespielt';

  @override
  String get winRate => 'Gewinnquote';

  @override
  String get currentStreak => 'Aktuelle Serie';

  @override
  String get maxStreak => 'Beste Serie';

  @override
  String get play => 'Spielen';

  @override
  String get mostPopular => 'Beliebteste';

  @override
  String get bestValue => 'Bestes Angebot';

  @override
  String get dailyAlreadyPlayed =>
      'Du hast das heutige Rätsel schon gelöst. Komm morgen wieder!';

  @override
  String get dailyLoginTitle => 'Tagesgeschenk';

  @override
  String dailyLoginClaim(Object coins) {
    return '$coins Münzen abholen';
  }

  @override
  String get dailyLoginClaimed => 'Komm morgen wieder für mehr';

  @override
  String get spinWheelTitle => 'Glücksrad';

  @override
  String get spinWheelAction => 'Jetzt drehen';

  @override
  String get spinWheelUsed => 'Komm morgen wieder zum Drehen';

  @override
  String spinWheelWon(Object coins) {
    return 'Du hast $coins Münzen gewonnen!';
  }

  @override
  String get score => 'Serie';

  @override
  String get submit => 'Senden';

  @override
  String get notAWord => 'Kein Wort';

  @override
  String get spinButton => 'DREHEN';

  @override
  String get free => 'GRATIS';

  @override
  String get claim => 'ABHOLEN';

  @override
  String get prizeHint => 'Tipp';

  @override
  String get prizeStrikeout => 'Streichen';

  @override
  String get prizeSkip => 'Skip';

  @override
  String get prizeSpin => 'Drehung';

  @override
  String get tabPuzzles => 'Rätsel';

  @override
  String get tabTrophies => 'Trophäen';

  @override
  String get monthlyPrizes => 'Monatsziele';

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Siege',
      one: '$count Sieg',
    );
    return '$_temp0';
  }

  @override
  String playDate(String date) {
    return '$date SPIELEN';
  }

  @override
  String get puzzleLocked => 'Dieses Rätsel ist noch nicht verfügbar';

  @override
  String get prizeClaimed => 'Preis abgeholt!';

  @override
  String get subBenefitNoAds => 'Nie wieder Werbung';

  @override
  String get subBenefitBonus => 'Täglicher Münzbonus, ohne Video';

  @override
  String get subBenefitDiscount => 'Günstigere Tipps und Streichungen';

  @override
  String get planMonthly => 'Monatlich';

  @override
  String get planYearly => 'Jährlich';

  @override
  String get subscriptionActive => 'Aktiv';

  @override
  String subscriptionRenews(Object date) {
    return 'Verlängert sich am $date';
  }

  @override
  String get guessDistribution => 'Verteilung der Versuche';

  @override
  String get resultWon => 'GENIAL!';

  @override
  String get resultLost => 'Knapp daneben!';

  @override
  String get resultWonSub => 'Du hast das Wort geknackt!';

  @override
  String get resultLostSub => 'Nächste Runde klappt\'s.';

  @override
  String get solutionLabel => 'Lösungswort';

  @override
  String get attemptsLabel => 'Versuche';

  @override
  String get streakLabel => 'Serie';

  @override
  String get shareResult => 'Ergebnis teilen';

  @override
  String get copiedToClipboard => 'Ergebnis kopiert!';

  @override
  String get ok => 'OK';

  @override
  String coinsEarned(Object coins) {
    return '$coins Münzen';
  }

  @override
  String get continueTitleStreak => 'Serie verlieren?';

  @override
  String continueBodyStreak(int streak) {
    return 'Willst du deine Serie von $streak wirklich verlieren?';
  }

  @override
  String get continueTitleNoStreak => 'Noch ein Versuch?';

  @override
  String get continueBodyNoStreak => 'Rette die Runde mit einem Extra-Versuch.';

  @override
  String get continueBuy => 'Extra-Versuch';

  @override
  String get continueDeclineStreak => 'Serie verlieren';

  @override
  String get continueDeclineNoStreak => 'Aufgeben';

  @override
  String get continueGetCoins => 'Münzen holen';
}
