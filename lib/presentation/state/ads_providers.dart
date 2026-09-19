import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/economy_config.dart';
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

final iapServiceProvider = Provider<IapService>((ref) {
  final service = InAppPurchaseService();
  ref.onDispose(service.dispose);
  return service;
});

final subscriptionServiceProvider = Provider((ref) => const SubscriptionService());
