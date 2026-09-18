import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/monetization/ads_service.dart';
import '../../services/monetization/iap_service.dart';
import '../../services/monetization/subscription_service.dart';

final adsServiceProvider = Provider<AdsService>((ref) {
  return AdMobAdsService();
});

final iapServiceProvider = Provider<IapService>((ref) {
  final service = InAppPurchaseService();
  ref.onDispose(service.dispose);
  return service;
});

final subscriptionServiceProvider = Provider((ref) => const SubscriptionService());
