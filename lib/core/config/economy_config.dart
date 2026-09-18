/// Central, non-hardcoded-in-UI configuration for all coin/economy values.
/// Kept as static constants for the MVP; swap the reads in here for a
/// Firebase Remote Config lookup later without touching call sites.
class EconomyConfig {
  const EconomyConfig._();

  static const int roundCompletionReward = 5;
  static const int hintCost = 150;
  static const int letterStrikeoutCost = 125;
  static const int rewardedAdCoins = 20;
  static const int dailySkipAllowance = 3;
  static const Duration skipRefillInterval = Duration(hours: 8);
  static const int interstitialAdEveryNRounds = 4;

  static const int dailyLoginBaseCoins = 10;
  static const int dailyLoginStreakBonus = 2;
  static const int dailyLoginMaxStreakDays = 7;

  /// Coin packages shown in the shop. `productId` maps to the store SKU;
  /// `priceLabel` is a fallback until the store returns localized pricing.
  static const List<CoinPackage> coinPackages = [
    CoinPackage(productId: 'coins_800', coins: 800, priceLabel: '2,99 €'),
    CoinPackage(productId: 'coins_1400', coins: 1400, priceLabel: '5,99 €'),
    CoinPackage(productId: 'coins_3200', coins: 3200, priceLabel: '9,99 €', badge: PackageBadge.mostPopular),
    CoinPackage(productId: 'coins_8600', coins: 8600, priceLabel: '22,99 €'),
    CoinPackage(productId: 'coins_26000', coins: 26000, priceLabel: '59,99 €', badge: PackageBadge.bestValue),
  ];

  static const String removeAdsProductId = 'remove_ads_lifetime';
  static const String subscriptionMonthlyId = 'wortiplex_plus_monthly';
  static const String subscriptionYearlyId = 'wortiplex_plus_yearly';

  static const String starterPackProductId = 'starter_pack';
  static const int starterPackCoins = 600;
  static const Duration starterPackAvailability = Duration(hours: 36);
}

enum PackageBadge { none, mostPopular, bestValue }

class CoinPackage {
  final String productId;
  final int coins;
  final String priceLabel;
  final PackageBadge badge;

  const CoinPackage({
    required this.productId,
    required this.coins,
    required this.priceLabel,
    this.badge = PackageBadge.none,
  });
}
