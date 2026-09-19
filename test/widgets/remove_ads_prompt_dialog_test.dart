import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:wortiplex/core/config/economy_config.dart';
import 'package:wortiplex/core/localization/app_localizations.dart';
import 'package:wortiplex/core/navigation/navigator_key.dart';
import 'package:wortiplex/presentation/state/ads_providers.dart';
import 'package:wortiplex/presentation/widgets/remove_ads_prompt_dialog.dart';
import 'package:wortiplex/services/monetization/iap_service.dart';
import 'package:wortiplex/services/monetization/revenue_cat_service.dart';

class _FakeRevenueCatService extends RevenueCatService {
  final bool storeFails;
  final List<String> bought = [];

  _FakeRevenueCatService({this.storeFails = false});

  @override
  Stream<AppPurchaseResult> get purchaseStream => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> buyNonConsumable(String productId) async {
    bought.add(productId);
  }

  @override
  Future<void> buyConsumable(String productId) async {}

  @override
  Future<List<StoreProduct>> queryProducts(Set<String> productIds) async => [];

  @override
  Future<CustomerInfo?> restorePurchases() async => null;
}

Widget _app(_FakeRevenueCatService rc) => ProviderScope(
      overrides: [
        revenueCatServiceProvider.overrideWithValue(rc),
        iapServiceProvider.overrideWithValue(rc),
      ],
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

Future<void> _open(WidgetTester tester) async {
  unawaited(RemoveAdsPromptDialog.show());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('uses the no_ads.png artwork', (tester) async {
    final rc = _FakeRevenueCatService(storeFails: true);
    await tester.pumpWidget(_app(rc));
    await _open(tester);

    final image = find.byWidgetPredicate(
      (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/no_ads.png',
    );
    expect(image, findsOneWidget);
  });

  testWidgets('falls back to the configured price when the store is unavailable', (tester) async {
    final rc = _FakeRevenueCatService(storeFails: true);
    await tester.pumpWidget(_app(rc));
    await _open(tester);

    expect(find.text('Ohne Werbung für ${EconomyConfig.removeAdsFallbackPrice}'), findsOneWidget);
  });

  testWidgets('buying starts the remove-ads purchase and closes the dialog', (tester) async {
    final rc = _FakeRevenueCatService(storeFails: true);
    await tester.pumpWidget(_app(rc));
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey('remove_ads_buy')));
    await tester.pumpAndSettle();

    expect(rc.bought, [EconomyConfig.removeAdsProductId]);
    expect(find.text('Keine Lust auf Werbung?'), findsNothing);
  });

  testWidgets('"maybe later" closes the dialog without buying', (tester) async {
    final rc = _FakeRevenueCatService(storeFails: true);
    await tester.pumpWidget(_app(rc));
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey('remove_ads_later')));
    await tester.pumpAndSettle();

    expect(rc.bought, isEmpty);
    expect(find.text('Keine Lust auf Werbung?'), findsNothing);
  });
}
