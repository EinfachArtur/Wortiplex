import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wortiplex/core/localization/app_localizations.dart';
import 'package:wortiplex/data/repositories/profile_repository.dart';
import 'package:wortiplex/domain/models/user_profile.dart';
import 'package:wortiplex/presentation/screens/daily/daily_puzzle_screen.dart';
import 'package:wortiplex/presentation/state/ads_providers.dart';
import 'package:wortiplex/presentation/state/profile_providers.dart';
import 'package:wortiplex/services/monetization/ads_service.dart';

class _MemoryRepo implements ProfileRepository {
  UserProfile profile;
  _MemoryRepo(this.profile);

  @override
  Future<UserProfile> load() async => profile;

  @override
  Future<void> save(UserProfile p) async => profile = p;
}

class _FakeAdsService implements AdsService {
  bool rewardedLoaded = false;
  bool rewardedShown = false;

  @override
  Future<void> initialize() async {}

  @override
  BannerAd createBannerAd({required void Function() onLoaded, required void Function() onFailed}) {
    throw UnimplementedError();
  }

  @override
  Future<void> loadInterstitial() async {}

  @override
  Future<bool> showInterstitialIfReady({VoidCallback? onClosed}) async => false;

  @override
  Future<void> loadRewarded() async {
    rewardedLoaded = true;
  }

  @override
  Future<bool> showRewardedIfReady({required void Function(int amount) onReward}) async {
    rewardedShown = true;
    onReward(0);
    return true;
  }

  @override
  void onRoundCompleted({VoidCallback? onAdClosed}) {}
}

void main() {
  testWidgets('selecting a past unplayed day shows 150 gold and free ad buttons', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final fakeAds = _FakeAdsService();
    final today = DateTime.now();
    final pastDay = today.day > 1 ? today.day - 1 : 1;

    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(_MemoryRepo(UserProfile.fresh('test').copyWith(coins: 500))),
        adsServiceProvider.overrideWithValue(fakeAds),
      ],
    );
    addTearDown(container.dispose);
    await container.read(profileControllerProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DailyPuzzleScreen(),
        ),
      ),
    );
    await tester.pump();

    if (today.day > 1) {
      // Tap on past day
      await tester.tap(find.text('$pastDay').first);
      await tester.pump();

      // Should find the 150 coins option and the GRATIS ad option
      expect(find.text('150'), findsOneWidget);
      expect(find.text('GRATIS'), findsOneWidget);

      // Tap the 150 coins button
      await tester.tap(find.text('150'));
      await tester.pump();

      // Profile should have 500 - 150 = 350 coins
      final updatedProfile = container.read(profileControllerProvider).requireValue;
      expect(updatedProfile.coins, 350);
    }
  });
}
