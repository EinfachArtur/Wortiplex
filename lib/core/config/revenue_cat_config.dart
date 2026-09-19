import 'dart:io' show Platform;

class RevenueCatConfig {
  const RevenueCatConfig._();

  // ─── RevenueCat API Keys ──────────────────────────────────────────────────
  // WortiPlex API-Key aus deinem RevenueCat Dashboard:
  static const String apiKeyWortiplex = 'test_iiQjSeGAMsXTfWunxalCzygxTwa';

  // Optionale plattformspezifische Keys (falls du später separate App Store / Play Store Keys nutzt):
  static const String googleApiKey = apiKeyWortiplex;
  static const String appleApiKey = apiKeyWortiplex;

  static String get apiKey => apiKeyWortiplex;

  // ─── Entitlement Identifiers ──────────────────────────────────────────────
  // Müssen exakt mit den Entitlements in deinem RevenueCat Dashboard übereinstimmen.
  static const String entitlementPremium = 'premium';
  static const String entitlementRemoveAds = 'remove_ads';

  // ─── Offering Identifiers ─────────────────────────────────────────────────
  static const String offeringDefault = 'default';
  static const String offeringStarterPack = 'starter_pack';

  // ─── Package / Product Identifiers ────────────────────────────────────────
  static const String packageMonthly = 'monthly';
  static const String packageAnnual = 'annual';
  static const String packageLifetime = 'lifetime';
}
