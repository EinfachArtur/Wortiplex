import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domain/economy/ad_cadence.dart';

/// AdMob test unit IDs (safe to ship during development). Replace with real
/// ad unit IDs from the AdMob console before release, ideally injected via
/// build-time config rather than hardcoded here.
class AdUnitIds {
  const AdUnitIds._();

  static String get banner => defaultTargetPlatformIsIOS ? _iosBanner : _androidBanner;
  static String get interstitial => defaultTargetPlatformIsIOS ? _iosInterstitial : _androidInterstitial;
  static String get rewarded => defaultTargetPlatformIsIOS ? _iosRewarded : _androidRewarded;

  static const _androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  // Google's test *video* interstitials, so development shows real ad clips.
  static const _androidInterstitial = 'ca-app-pub-3940256099942544/8691691433';
  static const _androidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _iosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const _iosInterstitial = 'ca-app-pub-3940256099942544/5135589807';
  static const _iosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  static bool get defaultTargetPlatformIsIOS => defaultTargetPlatform == TargetPlatform.iOS;
}

abstract class AdsService {
  Future<void> initialize();
  BannerAd createBannerAd({required void Function() onLoaded, required void Function() onFailed});
  Future<void> loadInterstitial();
  Future<bool> showInterstitialIfReady();
  Future<void> loadRewarded();
  Future<bool> showRewardedIfReady({required void Function(int amount) onReward});
  void onRoundCompleted(); // called every finished round to drive interstitial cadence
}

class AdMobAdsService implements AdsService {
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false;
  final AdCadence _cadence;

  AdMobAdsService({int interstitialEveryNRounds = 1}) : _cadence = AdCadence(everyNRounds: interstitialEveryNRounds);

  @override
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    await loadInterstitial();
    await loadRewarded();
  }

  @override
  BannerAd createBannerAd({required void Function() onLoaded, required void Function() onFailed}) {
    final ad = BannerAd(
      adUnitId: AdUnitIds.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed();
        },
      ),
    );
    ad.load();
    return ad;
  }

  @override
  Future<void> loadInterstitial() async {
    if (_interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: AdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (_) {
          _interstitial = null;
          _loadingInterstitial = false;
        },
      ),
    );
  }

  @override
  Future<bool> showInterstitialIfReady() async {
    final ad = _interstitial;
    if (ad == null) return false;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadInterstitial();
      },
    );
    await ad.show();
    return true;
  }

  @override
  Future<void> loadRewarded() async {
    await RewardedAd.load(
      adUnitId: AdUnitIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  @override
  Future<bool> showRewardedIfReady({required void Function(int amount) onReward}) async {
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadRewarded();
      },
    );
    var rewarded = false;
    await ad.show(onUserEarnedReward: (ad, reward) {
      rewarded = true;
      onReward(reward.amount.toInt());
    });
    return rewarded;
  }

  @override
  void onRoundCompleted() {
    if (!_cadence.onRoundCompleted()) return;
    // If no clip has loaded (e.g. offline) the player simply continues; try to
    // have one ready for the next round.
    showInterstitialIfReady().then((shown) {
      if (!shown) loadInterstitial();
    });
  }
}

/// No-op implementation used when ads are disabled (subscriber / ad-free
/// purchase) or in tests, so UI code never needs to branch on ad-free state.
class NoOpAdsService implements AdsService {
  @override
  Future<void> initialize() async {}

  @override
  BannerAd createBannerAd({required void Function() onLoaded, required void Function() onFailed}) {
    throw UnsupportedError('Ads are disabled; do not request a banner.');
  }

  @override
  Future<void> loadInterstitial() async {}

  @override
  Future<bool> showInterstitialIfReady() async => false;

  @override
  Future<void> loadRewarded() async {}

  @override
  Future<bool> showRewardedIfReady({required void Function(int amount) onReward}) async => false;

  @override
  void onRoundCompleted() {}
}
