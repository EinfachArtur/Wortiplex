// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'WortiPlex';

  @override
  String get menuClassic => 'Classico';

  @override
  String get menuDaily => 'Sfida del giorno';

  @override
  String get menuWordFever => 'Word Fever';

  @override
  String get menuSecretWord => 'Parola segreta';

  @override
  String get menuTogether => 'WortiPlex Together';

  @override
  String get comingSoon => 'Prossimamente';

  @override
  String get coins => 'Monete';

  @override
  String get shop => 'Negozio';

  @override
  String get settings => 'Impostazioni';

  @override
  String get statistics => 'Statistiche';

  @override
  String get howToPlay => 'Come si gioca';

  @override
  String get language => 'Lingua';

  @override
  String get hint => 'Suggerimento';

  @override
  String get strikeOutLetter => 'Elimina una lettera';

  @override
  String get skip => 'Salta';

  @override
  String get newGame => 'Nuova partita';

  @override
  String get youWon => 'Hai vinto!';

  @override
  String get youLost => 'Tentativi finiti';

  @override
  String solutionWas(Object word) {
    return 'La parola era $word';
  }

  @override
  String get notEnoughLetters => 'Lettere insufficienti';

  @override
  String get notInWordList => 'Non è nella lista di parole';

  @override
  String get notEnoughCoins => 'Monete insufficienti';

  @override
  String get watchAdFor20Coins => 'Guarda una pubblicità per 20 monete';

  @override
  String get removeAds => 'Rimuovi pubblicità';

  @override
  String get restorePurchases => 'Ripristina acquisti';

  @override
  String get subscriptionTitle => 'WortiPlex+';

  @override
  String get gamesPlayed => 'Partite giocate';

  @override
  String get winRate => 'Percentuale vittorie';

  @override
  String get currentStreak => 'Serie attuale';

  @override
  String get maxStreak => 'Serie migliore';

  @override
  String get play => 'Gioca';

  @override
  String get mostPopular => 'Più popolare';

  @override
  String get bestValue => 'Miglior offerta';

  @override
  String get dailyAlreadyPlayed =>
      'Hai già risolto la sfida di oggi. Torna domani!';

  @override
  String get dailyLoginTitle => 'Regalo del giorno';

  @override
  String dailyLoginClaim(Object coins) {
    return 'Ritira $coins monete';
  }

  @override
  String get dailyLoginClaimed => 'Torna domani per altre';

  @override
  String get spinWheelTitle => 'Ruota della fortuna';

  @override
  String get spinWheelAction => 'Gira ora';

  @override
  String get spinWheelUsed => 'Torna domani per girare di nuovo';

  @override
  String spinWheelWon(Object coins) {
    return 'Hai vinto $coins monete!';
  }

  @override
  String get score => 'Serie';

  @override
  String get submit => 'Invia';

  @override
  String get notAWord => 'Non è una parola';

  @override
  String get spinButton => 'GIRA';

  @override
  String get free => 'GRATIS';

  @override
  String get claim => 'RITIRA';

  @override
  String get prizeHint => 'Suggerimento';

  @override
  String get prizeStrikeout => 'Elimina';

  @override
  String get prizeSkip => 'Salta';

  @override
  String get prizeSpin => 'Giro';

  @override
  String get tabPuzzles => 'Sfide';

  @override
  String get tabTrophies => 'Trofei';

  @override
  String get monthlyPrizes => 'Obiettivi del mese';

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vittorie',
      one: '$count vittoria',
    );
    return '$_temp0';
  }

  @override
  String playDate(String date) {
    return 'GIOCA $date';
  }

  @override
  String get puzzleLocked => 'Questa sfida non è ancora disponibile';

  @override
  String get prizeClaimed => 'Premio ritirato!';

  @override
  String get subBenefitNoAds => 'Mai più pubblicità';

  @override
  String get subBenefitBonus => 'Bonus monete giornaliero, senza video';

  @override
  String get subBenefitDiscount => 'Suggerimenti ed eliminazioni più economici';

  @override
  String get planMonthly => 'Mensile';

  @override
  String get planYearly => 'Annuale';

  @override
  String get subscriptionActive => 'Attivo';

  @override
  String subscriptionRenews(Object date) {
    return 'Si rinnova il $date';
  }

  @override
  String get guessDistribution => 'Distribuzione dei tentativi';

  @override
  String get resultWon => 'FANTASTICO!';

  @override
  String get resultLost => 'Quasi!';

  @override
  String get resultWonSub => 'Hai indovinato la parola!';

  @override
  String get resultLostSub => 'Andrà meglio la prossima volta.';

  @override
  String get solutionLabel => 'Parola da indovinare';

  @override
  String get attemptsLabel => 'Tentativi';

  @override
  String get streakLabel => 'Serie';

  @override
  String get shareResult => 'Condividi risultato';

  @override
  String get copiedToClipboard => 'Risultato copiato!';

  @override
  String get ok => 'OK';

  @override
  String coinsEarned(Object coins) {
    return '$coins monete';
  }

  @override
  String get continueTitleStreak => 'Perdere la serie?';

  @override
  String continueBodyStreak(int streak) {
    return 'Vuoi davvero perdere la tua serie di $streak?';
  }

  @override
  String get continueTitleNoStreak => 'Un altro tentativo?';

  @override
  String get continueBodyNoStreak =>
      'Salva questo turno con un tentativo extra.';

  @override
  String get continueBuy => 'Tentativo extra';

  @override
  String get continueDeclineStreak => 'Perdi la serie';

  @override
  String get continueDeclineNoStreak => 'Arrenditi';

  @override
  String get continueGetCoins => 'Ottieni monete';

  @override
  String get mainMenu => 'Menu principale';

  @override
  String get removeAdsPromptTitle => 'Stanco della pubblicità?';

  @override
  String get removeAdsPromptBody => 'Gioca senza interruzioni tra i turni.';

  @override
  String get removeAdsPromptOnce => 'Un solo pagamento, per sempre';

  @override
  String removeAdsPromptBuy(String price) {
    return 'Senza pubblicità per $price';
  }

  @override
  String get removeAdsPromptLater => 'Forse più tardi';

  @override
  String get boosterHintTitle => 'Booster suggerimenti';

  @override
  String get boosterStrikeoutTitle => 'Booster eliminazione';

  @override
  String get boosterSkipTitle => 'Booster salto';

  @override
  String boosterGet(int count) {
    return 'Prendi $count';
  }

  @override
  String boosterOwned(int count) {
    return 'Ne hai $count';
  }

  @override
  String get boosterBought => 'Acquistato!';

  @override
  String wordFeverDesc(int seconds) {
    return '$seconds secondi contro il tempo';
  }

  @override
  String wordFeverBest(int score) {
    return 'Record: $score';
  }

  @override
  String get feverScore => 'Punti';

  @override
  String get feverTimeUp => 'Tempo scaduto!';

  @override
  String get feverWordsSolved => 'Parole risolte';

  @override
  String get feverBestLabel => 'Record';

  @override
  String get feverNewBest => 'Nuovo record!';

  @override
  String get feverPlayAgain => 'Rigioca';

  @override
  String get playerId => 'ID giocatore';

  @override
  String get playerIdCopied => 'ID giocatore copiato negli appunti';

  @override
  String get playerIdTapToCopy => 'Tocca per copiare';

  @override
  String get menuDateGuess => 'Indovina la data';

  @override
  String dateGuessDesc(int minYear, int maxYear) {
    return 'Indovina la data tra il $minYear e il $maxYear';
  }

  @override
  String get dateFormatHint => 'GG MM AAAA';

  @override
  String get notAValidDate => 'Non è una data valida';

  @override
  String get notEnoughDigits => 'Cifre insufficienti';
}
