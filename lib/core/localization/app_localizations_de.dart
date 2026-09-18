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
}
