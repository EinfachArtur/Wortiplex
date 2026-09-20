import 'dart:io' show Platform;

class RevenueCatConfig {
  const RevenueCatConfig._();

  // ─── RevenueCat API Keys ──────────────────────────────────────────────────
  // WortiPlex API-Keys aus deinem RevenueCat Dashboard:
  static const String appleApiKey = 'appl_AFhLAHLHfXAnXwfTahHrPApLhXS';
  static const String googleApiKey = 'test_iiQjSeGAMsXTfWunxalCzygxTwa';

  static String get apiKey => Platform.isIOS || Platform.isMacOS ? appleApiKey : googleApiKey;

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
