import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wortiplex/core/config/economy_config.dart';
import 'package:wortiplex/core/localization/app_localizations.dart';
import 'package:wortiplex/core/navigation/navigator_key.dart';
import 'package:wortiplex/presentation/state/ads_providers.dart';
import 'package:wortiplex/presentation/widgets/remove_ads_prompt_dialog.dart';
import 'package:wortiplex/services/monetization/iap_service.dart';

class _FakeIap implements IapService {
  final List<ProductDetails> products;
  final bool storeFails;
  final List<String> bought = [];

  _FakeIap({this.products = const [], this.storeFails = false});

  @override
  Stream<PurchaseResult> get purchaseStream => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<List<ProductDetails>> queryProducts(Set<String> productIds) async {
    if (storeFails) throw StateError('no store');
    return products;
  }

  @override
  Future<void> buyConsumable(String productId) async {}

  @override
  Future<void> buyNonConsumable(String productId) async => bought.add(productId);

  @override
  Future<void> restorePurchases() async {}

  @override
  void dispose() {}
}

Widget _app(_FakeIap iap) => ProviderScope(
      overrides: [iapServiceProvider.overrideWithValue(iap)],
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
  testWidgets('shows the store price on the buy button', (tester) async {
    final iap = _FakeIap(
      products: [
        ProductDetails(
          id: EconomyConfig.removeAdsProductId,
          title: 'Remove ads',
          description: '',
          price: '8,49 €',
          rawPrice: 8.49,
          currencyCode: 'EUR',
        ),
      ],
    );
    await tester.pumpWidget(_app(iap));
    await _open(tester);

    expect(find.text('Keine Lust auf Werbung?'), findsOneWidget);
    expect(find.text('Ohne Werbung für 8,49 €'), findsOneWidget);
  });

  testWidgets('uses the no_ads.png artwork', (tester) async {
    await tester.pumpWidget(_app(_FakeIap(storeFails: true)));
    await _open(tester);

    final image = find.byWidgetPredicate(
      (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/no_ads.png',
    );
    expect(image, findsOneWidget);
  });

  testWidgets('falls back to the configured price when the store is unavailable', (tester) async {
    await tester.pumpWidget(_app(_FakeIap(storeFails: true)));
    await _open(tester);

    expect(find.text('Ohne Werbung für ${EconomyConfig.removeAdsFallbackPrice}'), findsOneWidget);
  });

  testWidgets('buying starts the remove-ads purchase and closes the dialog', (tester) async {
    final iap = _FakeIap(storeFails: true);
    await tester.pumpWidget(_app(iap));
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey('remove_ads_buy')));
    await tester.pumpAndSettle();

    expect(iap.bought, [EconomyConfig.removeAdsProductId]);
    expect(find.text('Keine Lust auf Werbung?'), findsNothing);
  });

  testWidgets('"maybe later" closes the dialog without buying', (tester) async {
    final iap = _FakeIap(storeFails: true);
    await tester.pumpWidget(_app(iap));
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey('remove_ads_later')));
    await tester.pumpAndSettle();

    expect(iap.bought, isEmpty);
    expect(find.text('Keine Lust auf Werbung?'), findsNothing);
  });
}
