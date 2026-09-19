import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wortiplex/core/config/word_fever_config.dart';
import 'package:wortiplex/core/localization/app_localizations.dart';
import 'package:wortiplex/data/repositories/profile_repository.dart';
import 'package:wortiplex/data/repositories/word_repository.dart';
import 'package:wortiplex/domain/models/game_mode.dart';
import 'package:wortiplex/domain/models/language.dart';
import 'package:wortiplex/domain/models/user_profile.dart';
import 'package:wortiplex/presentation/screens/game_board/game_board_screen.dart';
import 'package:wortiplex/presentation/state/ads_providers.dart';
import 'package:wortiplex/presentation/state/game_providers.dart';
import 'package:wortiplex/presentation/state/profile_providers.dart';
import 'package:wortiplex/presentation/widgets/virtual_keyboard.dart';
import 'package:wortiplex/services/monetization/ads_service.dart';

class _MemoryRepo implements ProfileRepository {
  UserProfile profile = UserProfile.fresh('t');

  @override
  Future<UserProfile> load() async => profile;

  @override
  Future<void> save(UserProfile p) async => profile = p;
}

/// Only one solution, so the test knows every word.
class _OneWordRepo implements WordRepository {
  @override
  Future<WordList> loadWordList(Language language) async =>
      const WordList(solutions: ['HALLO'], validGuesses: ['HALLO', 'WORTE']);

  @override
  Future<String> randomSolution(Language language, {Random? random}) async => 'HALLO';
}

class _NoAds implements AdsService {
  int rounds = 0;

  @override
  Future<void> initialize() async {}

  @override
  BannerAd createBannerAd({required void Function() onLoaded, required void Function() onFailed}) =>
      throw UnsupportedError('no banners in tests');

  @override
  Future<void> loadInterstitial() async {}

  @override
  Future<bool> showInterstitialIfReady({VoidCallback? onClosed}) async => false;

  @override
  Future<void> loadRewarded() async {}

  @override
  Future<bool> showRewardedIfReady({required void Function(int amount) onReward}) async => false;

  @override
  void onRoundCompleted({VoidCallback? onAdClosed}) => rounds++;
}

Future<(ProviderContainer, _MemoryRepo, _NoAds)> _pumpFever(WidgetTester tester) async {
  // The booster cost chips overflow by a few pixels with the test font.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);

  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  final repo = _MemoryRepo();
  final ads = _NoAds();
  final container = ProviderContainer(overrides: [
    profileRepositoryProvider.overrideWithValue(repo),
    wordRepositoryProvider.overrideWithValue(_OneWordRepo()),
    adsServiceProvider.overrideWithValue(ads),
  ]);
  addTearDown(container.dispose);
  await container.read(profileControllerProvider.future);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const GameBoardScreen(mode: GameMode.wordFever),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return (container, repo, ads);
}

Future<void> _typeHallo(WidgetTester tester) async {
  for (final letter in ['H', 'A', 'L', 'L', 'O']) {
    await tester.tap(find.descendant(of: find.byType(VirtualKeyboard), matching: find.text(letter)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.tap(find.text('SENDEN'));
  await tester.pump();
}

void main() {
  testWidgets('the clock counts down once a run has started', (tester) async {
    await _pumpFever(tester);
    expect(find.text('1:30'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('1:27'), findsOneWidget);
  });

  testWidgets('solving a word scores, adds time and deals the next word', (tester) async {
    await _pumpFever(tester);
    await tester.pump(const Duration(seconds: 2));

    await _typeHallo(tester);
    // Reveal + win wave run with the clock paused.
    await tester.pump(const Duration(seconds: 4));

    const score = WordFeverConfig.basePoints + 5 * WordFeverConfig.pointsPerAttemptLeft;
    expect(find.text('$score'), findsOneWidget, reason: 'score chip');
    // Without the +10s bonus the clock would read about 1:26 by now.
    final clock = find.descendant(of: find.byKey(const ValueKey('fever_clock')), matching: find.byType(Text));
    final shown = tester.widgetList<Text>(clock).map((t) => t.data).join(' ');
    expect(shown, contains('1:3'));

    // The board is cleared for the next word: the keyboard letters are enabled again
    // and a new guess can be entered.
    await _typeHallo(tester);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('${score + WordFeverConfig.basePoints + 5 * WordFeverConfig.pointsPerAttemptLeft + WordFeverConfig.pointsPerCombo}'), findsOneWidget);
  });

  testWidgets('when time is up the result dialog pays out and stores the record', (tester) async {
    final (container, repo, ads) = await _pumpFever(tester);
    await tester.pump(const Duration(seconds: 2));
    await _typeHallo(tester);
    await tester.pump(const Duration(seconds: 4));
    final coinsBefore = container.read(profileControllerProvider).value!.coins;

    await tester.pump(const Duration(seconds: 120));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Zeit abgelaufen!'), findsOneWidget);
    expect(find.byKey(const ValueKey('fever_score')), findsOneWidget);
    final profile = container.read(profileControllerProvider).value!;
    expect(profile.wordFeverBest, 200);
    expect(profile.coins, coinsBefore + WordFeverConfig.coinsPerWord);
    expect(repo.profile.wordFeverBest, 200);
    expect(ads.rounds, 1);

    // "Play again" starts a fresh run.
    await tester.tap(find.byKey(const ValueKey('fever_again')));
    await tester.pump(); // the closing animation starts on the first frame
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Zeit abgelaufen!'), findsNothing);
    expect(find.text('1:30'), findsOneWidget);
  });
}
