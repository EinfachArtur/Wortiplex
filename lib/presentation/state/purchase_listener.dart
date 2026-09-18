import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/economy_config.dart';
import '../../domain/economy/coin_transaction.dart';
import '../../services/monetization/iap_service.dart';
import 'ads_providers.dart';
import 'profile_providers.dart';

/// Activates the app-wide purchase listener. Read (not watched) once near
/// the root of the widget tree so the subscription lives for the app's
/// lifetime and purchase results are applied exactly once, regardless of
/// which screen initiated the purchase.
final purchaseListenerProvider = Provider<void>((ref) {
  final iap = ref.watch(iapServiceProvider);
  final subscriptionService = ref.watch(subscriptionServiceProvider);

  final sub = iap.purchaseStream.listen((result) async {
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

  ref.onDispose(sub.cancel);
});
