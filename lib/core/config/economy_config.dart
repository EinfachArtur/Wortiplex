import '../../domain/economy/monthly_prizes.dart';

/// Central, non-hardcoded-in-UI configuration for all coin/economy values.
/// Kept as static constants for the MVP; swap the reads in here for a
/// Firebase Remote Config lookup later without touching call sites.
class EconomyConfig {
  const EconomyConfig._();

  static const int roundCompletionReward = 5;
  static const int hintCost = 150;
  static const int letterStrikeoutCost = 125;
  static const int skipCost = 200;
  static const int rewardedAdCoins = 20;
  static const int dailySkipAllowance = 3;
  static const Duration skipRefillInterval = Duration(hours: 8);
  /// A full-screen ad clip follows every finished round (ad-free players excepted).
  static const int interstitialAdEveryNRounds = 1;

  /// After every Nth ad clip a "go ad-free" offer is shown; the price label is
  /// only a fallback until the store returns the localized price.
  static const int removeAdsPromptEveryNAds = 1;
  static const String removeAdsFallbackPrice = '9,99 €';

  static const int dailyLoginBaseCoins = 10;
  static const int dailyLoginStreakBonus = 2;
  static const int dailyLoginMaxStreakDays = 7;

  static const int spinCost = 150;

  /// Price of one extra attempt after losing a round, and how many a single
  /// round may contain.
  static const int extraAttemptCost = 400;
  static const int maxExtraAttemptsPerRound = 1;
  static const MonthlyPrizes monthlyPrizes = MonthlyPrizes([
    MonthlyPrizeTier(3, 50),
    MonthlyPrizeTier(10, 150),
    MonthlyPrizeTier(30, 500),
  ]);

  /// Coin packages shown in the shop. `productId` maps to the store SKU;
  /// `priceLabel` is a fallback until the store returns localized pricing.
  static const List<CoinPackage> coinPackages = [
    CoinPackage(productId: 'coins_800', coins: 800, priceLabel: '2,99 €'),
    CoinPackage(productId: 'coins_1400', coins: 1400, priceLabel: '5,99 €'),
    CoinPackage(productId: 'coins_3200', coins: 3200, priceLabel: '9,99 €', badge: PackageBadge.mostPopular),
    CoinPackage(productId: 'coins_8600', coins: 8600, priceLabel: '22,99 €'),
    CoinPackage(productId: 'coins_26000', coins: 26000, priceLabel: '59,99 €', badge: PackageBadge.bestValue),
  ];

  /// Shop booster offers: one item at its base price, or a discounted bundle.
  static const int boosterBundleSize = 3;
  static const Map<BoosterKind, BoosterPrice> boosterPrices = {
    BoosterKind.hint: BoosterPrice(single: hintCost, bundle: 425),
    BoosterKind.strikeout: BoosterPrice(single: letterStrikeoutCost, bundle: 350),
    BoosterKind.skip: BoosterPrice(single: skipCost, bundle: 550),
  };

  static const String removeAdsProductId = 'remove_ads_lifetime';
  static const String subscriptionMonthlyId = 'wortiplex_plus_monthly';
  static const String subscriptionYearlyId = 'wortiplex_plus_yearly';

  static const String starterPackProductId = 'starter_pack';
  static const int starterPackCoins = 600;
  static const Duration starterPackAvailability = Duration(hours: 36);
}

enum BoosterKind { hint, strikeout, skip }

class BoosterPrice {
  final int single;
  final int bundle;
  const BoosterPrice({required this.single, required this.bundle});

  int forAmount(int amount) => amount == EconomyConfig.boosterBundleSize ? bundle : single * amount;
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
