import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/economy_config.dart';
import '../../domain/economy/ad_cadence.dart';
import '../../services/monetization/ads_service.dart';
import '../../services/monetization/iap_service.dart';
import '../../services/monetization/subscription_service.dart';

final adsServiceProvider = Provider<AdsService>((ref) {
  final service = AdMobAdsService(interstitialEveryNRounds: EconomyConfig.interstitialAdEveryNRounds);
  // Preload so a clip is ready when the first round ends.
  service.loadInterstitial();
  service.loadRewarded();
  return service;
});

/// Counts ad clips to decide when the "go ad-free" offer is due.
final removeAdsPromptCadenceProvider = Provider<AdCadence>(
  (ref) => AdCadence(everyNRounds: EconomyConfig.removeAdsPromptEveryNAds),
);

final iapServiceProvider = Provider<IapService>((ref) {
  final service = InAppPurchaseService();
  ref.onDispose(service.dispose);
  return service;
});

final subscriptionServiceProvider = Provider((ref) => const SubscriptionService());
