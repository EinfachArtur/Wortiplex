import '../../core/config/economy_config.dart';
import '../../domain/models/subscription_status.dart';

/// Translates raw store product IDs into domain [SubscriptionStatus] updates.
/// Subscription renewal/expiry itself is managed by the store; the app only
/// needs to react to purchase/restore events, which is why this is a thin
/// mapping layer rather than a stateful service.
class SubscriptionService {
  const SubscriptionService();

  SubscriptionStatus applyPurchase(SubscriptionStatus current, String productId) {
    if (productId == EconomyConfig.removeAdsProductId) {
      return current.copyWith(adsRemovedLifetime: true);
    }
    if (productId == EconomyConfig.subscriptionMonthlyId) {
      return current.copyWith(
        tier: SubscriptionTier.monthly,
        productId: productId,
        autoRenewing: true,
        expiresAt: DateTime.now().add(const Duration(days: 31)),
      );
    }
    if (productId == EconomyConfig.subscriptionYearlyId) {
      return current.copyWith(
        tier: SubscriptionTier.yearly,
        productId: productId,
        autoRenewing: true,
        expiresAt: DateTime.now().add(const Duration(days: 366)),
      );
    }
    return current;
  }
}
