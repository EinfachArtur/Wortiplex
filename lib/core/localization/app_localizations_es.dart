// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'WortiPlex';

  @override
  String get menuClassic => 'Clásico';

  @override
  String get menuDaily => 'Reto diario';

  @override
  String get menuWordFever => 'Word Fever';

  @override
  String get menuSecretWord => 'Palabra secreta';

  @override
  String get menuTogether => 'WortiPlex Together';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get coins => 'Monedas';

  @override
  String get shop => 'Tienda';

  @override
  String get settings => 'Ajustes';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get howToPlay => 'Cómo jugar';

  @override
  String get language => 'Idioma';

  @override
  String get hint => 'Pista';

  @override
  String get strikeOutLetter => 'Tachar una letra';

  @override
  String get skip => 'Saltar';

  @override
  String get newGame => 'Nueva partida';

  @override
  String get youWon => '¡Ganaste!';

  @override
  String get youLost => 'Sin intentos';

  @override
  String solutionWas(Object word) {
    return 'La palabra era $word';
  }

  @override
  String get notEnoughLetters => 'Faltan letras';

  @override
  String get notInWordList => 'No está en la lista de palabras';

  @override
  String get notEnoughCoins => 'No tienes suficientes monedas';

  @override
  String get watchAdFor20Coins => 'Ver un anuncio por 20 monedas';

  @override
  String get removeAds => 'Quitar anuncios';

  @override
  String get restorePurchases => 'Restaurar compras';

  @override
  String get subscriptionTitle => 'WortiPlex+';

  @override
  String get gamesPlayed => 'Partidas jugadas';

  @override
  String get winRate => '% de victorias';

  @override
  String get currentStreak => 'Racha actual';

  @override
  String get maxStreak => 'Mejor racha';

  @override
  String get play => 'Jugar';

  @override
  String get mostPopular => 'Más popular';

  @override
  String get bestValue => 'Mejor oferta';

  @override
  String get dailyAlreadyPlayed =>
      'Ya resolviste el reto de hoy. ¡Vuelve mañana!';

  @override
  String get dailyLoginTitle => 'Regalo diario';

  @override
  String dailyLoginClaim(Object coins) {
    return 'Reclamar $coins monedas';
  }

  @override
  String get dailyLoginClaimed => 'Vuelve mañana por más';

  @override
  String get spinWheelTitle => 'Rueda de la suerte';

  @override
  String get spinWheelAction => 'Girar';

  @override
  String get spinWheelUsed => 'Vuelve mañana para girar de nuevo';

  @override
  String spinWheelWon(Object coins) {
    return '¡Ganaste $coins monedas!';
  }

  @override
  String get score => 'Racha';

  @override
  String get submit => 'Enviar';

  @override
  String get notAWord => 'No es una palabra';

  @override
  String get spinButton => 'GIRAR';

  @override
  String get free => 'GRATIS';

  @override
  String get claim => 'RECLAMAR';

  @override
  String get prizeHint => 'Pista';

  @override
  String get prizeStrikeout => 'Tachar';

  @override
  String get prizeSkip => 'Saltar';

  @override
  String get prizeSpin => 'Giro';

  @override
  String get tabPuzzles => 'Retos';

  @override
  String get tabTrophies => 'Trofeos';

  @override
  String get monthlyPrizes => 'Metas del mes';

  @override
  String winsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count victorias',
      one: '$count victoria',
    );
    return '$_temp0';
  }

  @override
  String playDate(String date) {
    return 'JUGAR $date';
  }

  @override
  String get puzzleLocked => 'Este reto aún no está disponible';

  @override
  String get prizeClaimed => '¡Premio reclamado!';

  @override
  String get subBenefitNoAds => 'Nunca más anuncios';

  @override
  String get subBenefitBonus => 'Bono diario de monedas, sin vídeo';

  @override
  String get subBenefitDiscount => 'Pistas y tachones más baratos';

  @override
  String get planMonthly => 'Mensual';

  @override
  String get planYearly => 'Anual';

  @override
  String get subscriptionActive => 'Activo';

  @override
  String subscriptionRenews(Object date) {
    return 'Se renueva el $date';
  }

  @override
  String get guessDistribution => 'Distribución de intentos';

  @override
  String get resultWon => '¡GENIAL!';

  @override
  String get resultLost => '¡Casi!';

  @override
  String get resultWonSub => '¡Adivinaste la palabra!';

  @override
  String get resultLostSub => 'La próxima ronda será mejor.';

  @override
  String get solutionLabel => 'Palabra a adivinar';

  @override
  String get attemptsLabel => 'Intentos';

  @override
  String get streakLabel => 'Racha';

  @override
  String get shareResult => 'Compartir resultado';

  @override
  String get copiedToClipboard => '¡Resultado copiado!';

  @override
  String get ok => 'OK';

  @override
  String coinsEarned(Object coins) {
    return '$coins monedas';
  }

  @override
  String get continueTitleStreak => '¿Perder tu racha?';

  @override
  String continueBodyStreak(int streak) {
    return '¿De verdad quieres perder tu racha de $streak?';
  }

  @override
  String get continueTitleNoStreak => '¿Un intento más?';

  @override
  String get continueBodyNoStreak => 'Salva esta ronda con un intento extra.';

  @override
  String get continueBuy => 'Intento extra';

  @override
  String get continueDeclineStreak => 'Perder racha';

  @override
  String get continueDeclineNoStreak => 'Rendirse';

  @override
  String get continueGetCoins => 'Conseguir monedas';

  @override
  String get mainMenu => 'Menú principal';

  @override
  String get removeAdsPromptTitle => '¿Cansado de los anuncios?';

  @override
  String get removeAdsPromptBody => 'Juega sin interrupciones entre rondas.';

  @override
  String get removeAdsPromptOnce => 'Un solo pago, para siempre';

  @override
  String removeAdsPromptBuy(String price) {
    return 'Sin anuncios por $price';
  }

  @override
  String get removeAdsPromptLater => 'Quizás más tarde';

  @override
  String get boosterHintTitle => 'Potenciador de pistas';

  @override
  String get boosterStrikeoutTitle => 'Potenciador de tachones';

  @override
  String get boosterSkipTitle => 'Potenciador de saltos';

  @override
  String boosterGet(int count) {
    return 'Consigue $count';
  }

  @override
  String boosterOwned(int count) {
    return 'Tienes $count';
  }

  @override
  String get boosterBought => '¡Comprado!';

  @override
  String wordFeverDesc(int seconds) {
    return '$seconds s contrarreloj';
  }

  @override
  String wordFeverBest(int score) {
    return 'Récord: $score';
  }

  @override
  String get feverScore => 'Puntos';

  @override
  String get feverTimeUp => '¡Se acabó el tiempo!';

  @override
  String get feverWordsSolved => 'Palabras resueltas';

  @override
  String get feverBestLabel => 'Récord';

  @override
  String get feverNewBest => '¡Nuevo récord!';

  @override
  String get feverPlayAgain => 'Jugar de nuevo';

  @override
  String get playerId => 'ID de jugador';

  @override
  String get playerIdCopied => 'ID de jugador copiado al portapapeles';

  @override
  String get playerIdTapToCopy => 'Toca para copiar';
}
