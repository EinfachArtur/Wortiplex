import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/config/economy_config.dart';
import '../../domain/economy/ad_cadence.dart';
import '../../services/monetization/ads_service.dart';
import '../../services/monetization/iap_service.dart';
import '../../services/monetization/revenue_cat_service.dart';
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

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  final service = RevenueCatService();
  ref.onDispose(service.dispose);
  return service;
});

final iapServiceProvider = Provider<IapService>((ref) {
  return ref.watch(revenueCatServiceProvider);
});

final offeringsProvider = FutureProvider.autoDispose<Offerings?>((ref) async {
  final rc = ref.watch(revenueCatServiceProvider);
  return await rc.getOfferings();
});

final subscriptionServiceProvider = Provider((ref) => const SubscriptionService());
