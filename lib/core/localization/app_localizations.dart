import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Wortiplex'**
  String get appTitle;

  /// No description provided for @menuClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get menuClassic;

  /// No description provided for @menuDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Puzzle'**
  String get menuDaily;

  /// No description provided for @menuWordFever.
  ///
  /// In en, this message translates to:
  /// **'Word Fever'**
  String get menuWordFever;

  /// No description provided for @menuSecretWord.
  ///
  /// In en, this message translates to:
  /// **'Secret Word'**
  String get menuSecretWord;

  /// No description provided for @menuTogether.
  ///
  /// In en, this message translates to:
  /// **'Wortiplex Together'**
  String get menuTogether;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @coins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coins;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @howToPlay.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlay;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// No description provided for @strikeOutLetter.
  ///
  /// In en, this message translates to:
  /// **'Strike out letter'**
  String get strikeOutLetter;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get newGame;

  /// No description provided for @youWon.
  ///
  /// In en, this message translates to:
  /// **'You won!'**
  String get youWon;

  /// No description provided for @youLost.
  ///
  /// In en, this message translates to:
  /// **'Out of tries'**
  String get youLost;

  /// No description provided for @solutionWas.
  ///
  /// In en, this message translates to:
  /// **'The word was {word}'**
  String solutionWas(Object word);

  /// No description provided for @notEnoughLetters.
  ///
  /// In en, this message translates to:
  /// **'Not enough letters'**
  String get notEnoughLetters;

  /// No description provided for @notInWordList.
  ///
  /// In en, this message translates to:
  /// **'Not in word list'**
  String get notInWordList;

  /// No description provided for @notEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins'**
  String get notEnoughCoins;

  /// No description provided for @watchAdFor20Coins.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad for 20 coins'**
  String get watchAdFor20Coins;

  /// No description provided for @removeAds.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get removeAds;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Wortiplex+'**
  String get subscriptionTitle;

  /// No description provided for @gamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Played'**
  String get gamesPlayed;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win %'**
  String get winRate;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @maxStreak.
  ///
  /// In en, this message translates to:
  /// **'Max streak'**
  String get maxStreak;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get mostPopular;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get bestValue;

  /// No description provided for @dailyAlreadyPlayed.
  ///
  /// In en, this message translates to:
  /// **'You already solved today\'s puzzle. Come back tomorrow!'**
  String get dailyAlreadyPlayed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
