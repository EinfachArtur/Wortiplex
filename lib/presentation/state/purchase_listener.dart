import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/economy_config.dart';
import '../../core/config/revenue_cat_config.dart';
import '../../domain/economy/coin_transaction.dart';
import '../../domain/models/subscription_status.dart';
import '../../services/monetization/iap_service.dart';
import 'ads_providers.dart';
import 'profile_providers.dart';

/// Activates the app-wide purchase listener. Read (not watched) once near
/// the root of the widget tree so the subscription lives for the app's
/// lifetime and purchase results are applied exactly once, regardless of
/// which screen initiated the purchase.
final purchaseListenerProvider = Provider<void>((ref) {
  final rcService = ref.watch(revenueCatServiceProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);

  // 1. Purchase Stream Listener (Consumables, Coin Packs, Starter Packs)
  final purchaseSub = rcService.purchaseStream.listen((result) async {
    if (result.outcome != PurchaseOutcome.success) return;

    final productId = result.productId;
    final profileController = ref.read(profileControllerProvider.notifier);

    CoinPackage? coinPackage;
    for (final p in EconomyConfig.coinPackages) {
      if (p.productId == productId) {
        coinPackage = p;
        break;
      }
    }
    if (coinPackage != null) {
      await profileController.earnCoins(coinPackage.coins, CoinTransactionReason.iapPurchase);
      return;
    }

    if (productId == EconomyConfig.starterPackProductId) {
      await profileController.earnCoins(EconomyConfig.starterPackCoins, CoinTransactionReason.iapPurchase);
      final current = ref.read(profileControllerProvider).valueOrNull?.subscription;
      if (current != null) {
        await profileController.applySubscriptionUpdate(
          subscriptionService.applyPurchase(current, EconomyConfig.removeAdsProductId),
        );
      }
      return;
    }

    final current = ref.read(profileControllerProvider).valueOrNull?.subscription;
    if (current == null) return;
    final updated = subscriptionService.applyPurchase(current, productId);
    await profileController.applySubscriptionUpdate(updated);
  });

  // 2. RevenueCat CustomerInfo Listener (Real-time Entitlements & Subscriptions)
  final customerInfoSub = rcService.customerInfoStream.listen((customerInfo) async {
    final profileController = ref.read(profileControllerProvider.notifier);
    final current = ref.read(profileControllerProvider).valueOrNull?.subscription;
    if (current == null) return;

    final isPremiumActive = customerInfo.entitlements.active.containsKey(RevenueCatConfig.entitlementPremium) ||
        customerInfo.entitlements.active.containsKey('wortiplex_plus') ||
        customerInfo.entitlements.active.containsKey('pro');

    final isRemoveAdsActive = customerInfo.entitlements.active.containsKey(RevenueCatConfig.entitlementRemoveAds) ||
        customerInfo.nonSubscriptionTransactions.any((t) => t.productIdentifier == EconomyConfig.removeAdsProductId);

    if (isPremiumActive) {
      final entitlement = customerInfo.entitlements.active[RevenueCatConfig.entitlementPremium] ??
          customerInfo.entitlements.active.values.first;
      final isYearly = entitlement.productIdentifier.contains('yearly') ||
          entitlement.productIdentifier.contains('annual');
      final expiresDate = entitlement.expirationDate != null
          ? DateTime.tryParse(entitlement.expirationDate!)
          : null;

      final updated = current.copyWith(
        tier: isYearly ? SubscriptionTier.yearly : SubscriptionTier.monthly,
        productId: entitlement.productIdentifier,
        autoRenewing: entitlement.willRenew,
        expiresAt: expiresDate,
        adsRemovedLifetime: current.adsRemovedLifetime || isRemoveAdsActive,
      );
      await profileController.applySubscriptionUpdate(updated);
      debugPrint('[PurchaseListener] Premium Status über RevenueCat synchronisiert: $updated');
    } else if (isRemoveAdsActive) {
      final updated = current.copyWith(adsRemovedLifetime: true);
      await profileController.applySubscriptionUpdate(updated);
      debugPrint('[PurchaseListener] RemoveAds über RevenueCat synchronisiert');
    }
  });

  ref.onDispose(() {
    purchaseSub.cancel();
    customerInfoSub.cancel();
  });
});
