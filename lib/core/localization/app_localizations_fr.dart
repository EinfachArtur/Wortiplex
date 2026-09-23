// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'WortiPlex';

  @override
  String get menuClassic => 'Classique';

  @override
  String get menuDaily => 'Défi du jour';

  @override
  String get menuWordFever => 'Word Fever';

  @override
  String get menuSecretWord => 'Mot secret';

  @override
  String get menuTogether => 'WortiPlex Together';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get coins => 'Pièces';

  @override
  String get shop => 'Boutique';

  @override
  String get settings => 'Réglages';

  @override
  String get statistics => 'Statistiques';

  @override
  String get howToPlay => 'Règles du jeu';

  @override
  String get language => 'Langue';

  @override
  String get hint => 'Indice';

  @override
  String get strikeOutLetter => 'Barrer une lettre';

  @override
  String get skip => 'Passer';

  @override
  String get newGame => 'Nouvelle partie';

  @override
  String get youWon => 'Gagné !';

  @override
  String get youLost => 'Plus d\'essais';

  @override
  String solutionWas(Object word) {
    return 'Le mot était $word';
  }

  @override
  String get notEnoughLetters => 'Pas assez de lettres';

  @override
  String get notInWordList => 'Absent de la liste de mots';

  @override
  String get notEnoughCoins => 'Pas assez de pièces';

  @override
  String get watchAdFor20Coins => 'Regarder une pub pour 20 pièces';

  @override
  String get removeAds => 'Supprimer les publicités';

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get subscriptionTitle => 'WortiPlex+';

  @override
  String get gamesPlayed => 'Parties jouées';

  @override
  String get winRate => 'Taux de victoire';

  @override
  String get currentStreak => 'Série actuelle';

  @override
  String get maxStreak => 'Meilleure série';

  @override
  String get play => 'Jouer';

  @override
  String get mostPopular => 'Le plus populaire';

  @override
  String get bestValue => 'Meilleure offre';

  @override
  String get dailyAlreadyPlayed =>
      'Tu as déjà résolu le défi du jour. Reviens demain !';

  @override
  String get dailyLoginTitle => 'Cadeau du jour';

  @override
  String dailyLoginClaim(Object coins) {
    return 'Récupérer $coins pièces';
  }

  @override
  String get dailyLoginClaimed => 'Reviens demain pour plus';

  @override
  String get spinWheelTitle => 'Roue de la chance';

  @override
  String get spinWheelAction => 'Tourner';

  @override
  String get spinWheelUsed => 'Reviens demain pour tourner à nouveau';

  @override
  String spinWheelWon(Object coins) {
    return 'Tu as gagné $coins pièces !';
  }

  @override
  String get score => 'Série';

  @override
  String get submit => 'Valider';

  @override
  String get notAWord => 'Pas un mot';

  @override
  String get spinButton => 'TOURNER';

  @override
  String get free => 'GRATUIT';

  @override
  String get claim => 'RÉCUPÉRER';

  @override
  String get prizeHint => 'Indice';

  @override
  String get prizeStrikeout => 'Barrer';

  @override
  String get prizeSkip => 'Passer';

  @override
  String get prizeSpin => 'Tour';

  @override
  String get tabPuzzles => 'Défis';

  @override
  String get tabTrophies => 'Trophées';

  @override
  String get monthlyPrizes => 'Objectifs du mois';

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count victoires',
      one: '$count victoire',
    );
    return '$_temp0';
  }

  @override
  String playDate(String date) {
    return 'JOUER $date';
  }

  @override
  String get puzzleLocked => 'Ce défi n\'est pas encore disponible';

  @override
  String get prizeClaimed => 'Prix récupéré !';

  @override
  String get subBenefitNoAds => 'Plus jamais de pub';

  @override
  String get subBenefitBonus => 'Bonus de pièces quotidien, sans vidéo';

  @override
  String get subBenefitDiscount => 'Indices et lettres barrées moins chers';

  @override
  String get planMonthly => 'Mensuel';

  @override
  String get planYearly => 'Annuel';

  @override
  String get subscriptionActive => 'Actif';

  @override
  String subscriptionRenews(Object date) {
    return 'Renouvellement le $date';
  }

  @override
  String get guessDistribution => 'Répartition des essais';

  @override
  String get resultWon => 'GÉNIAL !';

  @override
  String get resultLost => 'Si près du but !';

  @override
  String get resultWonSub => 'Tu as trouvé le mot !';

  @override
  String get resultLostSub => 'La prochaine sera la bonne.';

  @override
  String get solutionLabel => 'Mot à trouver';

  @override
  String get attemptsLabel => 'Essais';

  @override
  String get streakLabel => 'Série';

  @override
  String get shareResult => 'Partager le résultat';

  @override
  String get copiedToClipboard => 'Résultat copié !';

  @override
  String get ok => 'OK';

  @override
  String coinsEarned(Object coins) {
    return '$coins pièces';
  }

  @override
  String get continueTitleStreak => 'Perdre ta série ?';

  @override
  String continueBodyStreak(int streak) {
    return 'Veux-tu vraiment perdre ta série de $streak ?';
  }

  @override
  String get continueTitleNoStreak => 'Un essai de plus ?';

  @override
  String get continueBodyNoStreak =>
      'Sauve cette manche avec un essai supplémentaire.';

  @override
  String get continueBuy => 'Essai supplémentaire';

  @override
  String get continueDeclineStreak => 'Perdre la série';

  @override
  String get continueDeclineNoStreak => 'Abandonner';

  @override
  String get continueGetCoins => 'Obtenir des pièces';

  @override
  String get mainMenu => 'Menu principal';

  @override
  String get removeAdsPromptTitle => 'Marre de la pub ?';

  @override
  String get removeAdsPromptBody => 'Joue sans interruption entre les manches.';

  @override
  String get removeAdsPromptOnce => 'Un seul paiement, pour toujours';

  @override
  String removeAdsPromptBuy(String price) {
    return 'Sans pub pour $price';
  }

  @override
  String get removeAdsPromptLater => 'Plus tard';

  @override
  String get boosterHintTitle => 'Boost d\'indices';

  @override
  String get boosterStrikeoutTitle => 'Boost lettres barrées';

  @override
  String get boosterSkipTitle => 'Boost de passe';

  @override
  String boosterGet(int count) {
    return 'Obtenir $count';
  }

  @override
  String boosterOwned(int count) {
    return 'Tu en as $count';
  }

  @override
  String get boosterBought => 'Acheté !';

  @override
  String wordFeverDesc(int seconds) {
    return '$seconds s contre la montre';
  }

  @override
  String wordFeverBest(int score) {
    return 'Record : $score';
  }

  @override
  String get feverScore => 'Score';

  @override
  String get feverTimeUp => 'Temps écoulé !';

  @override
  String get feverWordsSolved => 'Mots trouvés';

  @override
  String get feverBestLabel => 'Record';

  @override
  String get feverNewBest => 'Nouveau record !';

  @override
  String get feverPlayAgain => 'Rejouer';

  @override
  String get playerId => 'ID joueur';

  @override
  String get playerIdCopied => 'ID joueur copié dans le presse-papiers';

  @override
  String get playerIdTapToCopy => 'Toucher pour copier';
}
