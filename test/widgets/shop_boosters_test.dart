import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortiplex/core/config/economy_config.dart';
import 'package:wortiplex/core/localization/app_localizations.dart';
import 'package:wortiplex/data/repositories/profile_repository.dart';
import 'package:wortiplex/domain/economy/coin_transaction.dart';
import 'package:wortiplex/domain/models/user_profile.dart';
import 'package:wortiplex/presentation/screens/shop/shop_screen.dart';
import 'package:wortiplex/presentation/state/profile_providers.dart';

class _MemoryRepo implements ProfileRepository {
  UserProfile profile;
  _MemoryRepo(this.profile);

  @override
  Future<UserProfile> load() async => profile;

  @override
  Future<void> save(UserProfile p) async => profile = p;
}

Future<ProviderContainer> _pumpShop(WidgetTester tester, {int coins = 10000}) async {
  tester.view.physicalSize = const Size(1080, 4200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [profileRepositoryProvider.overrideWithValue(_MemoryRepo(UserProfile.fresh('test')))],
  );
  addTearDown(container.dispose);
  await container.read(profileControllerProvider.future);
  // The controller tops up new profiles; pin the balance for the test.
  final notifier = container.read(profileControllerProvider.notifier);
  final current = container.read(profileControllerProvider).value!.coins;
  if (current > coins) await notifier.spendCoins(current - coins, CoinTransactionReason.spinPurchase);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ShopScreen(),
    ),
  ));
  await tester.pump();
  return container;
}

Finder _offer(String section, String offer) =>
    find.descendant(of: find.byKey(ValueKey(section)), matching: find.byKey(ValueKey(offer)));

void main() {
  testWidgets('shows the single and bundle artwork for every booster', (tester) async {
    await _pumpShop(tester);

    for (final name in [
      'glühbirne_1', 'glühbirne_2', 'fadenkreuz_1', 'fadenkreuz_2', 'Skip_1', 'Skip_2',
    ]) {
      expect(
        find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == 'assets/images/$name.png'),
        findsOneWidget,
        reason: name,
      );
    }
    expect(find.text('TIPP-BOOSTER'), findsOneWidget);
  });

  testWidgets('shows the configured prices', (tester) async {
    await _pumpShop(tester);

    expect(find.descendant(of: _offer('booster_hint', 'offer_single'), matching: find.text('150')), findsOneWidget);
    expect(find.descendant(of: _offer('booster_hint', 'offer_bundle'), matching: find.text('425')), findsOneWidget);
    expect(find.descendant(of: _offer('booster_strikeout', 'offer_single'), matching: find.text('125')), findsOneWidget);
    expect(find.descendant(of: _offer('booster_strikeout', 'offer_bundle'), matching: find.text('350')), findsOneWidget);
    expect(find.descendant(of: _offer('booster_skip', 'offer_single'), matching: find.text('200')), findsOneWidget);
    expect(find.descendant(of: _offer('booster_skip', 'offer_bundle'), matching: find.text('550')), findsOneWidget);
  });

  testWidgets('buying a bundle spends coins and adds the boosters', (tester) async {
    final container = await _pumpShop(tester, coins: 1000);

    await tester.tap(_offer('booster_hint', 'offer_bundle'));
    await tester.pump();

    final profile = container.read(profileControllerProvider).value!;
    expect(profile.coins, 1000 - 425);
    expect(profile.hintTokens, 3);
    expect(find.text('Gekauft!'), findsOneWidget);
  });

  testWidgets('buying a single strike-out and skip credits the right counter', (tester) async {
    final container = await _pumpShop(tester, coins: 1000);

    await tester.tap(_offer('booster_strikeout', 'offer_single'));
    await tester.pump();
    await tester.tap(_offer('booster_skip', 'offer_single'));
    await tester.pump();

    final profile = container.read(profileControllerProvider).value!;
    expect(profile.coins, 1000 - 125 - 200);
    expect(profile.strikeoutTokens, 1);
    expect(profile.skipsAvailable, UserProfile.fresh('x').skipsAvailable + 1);
  });

  testWidgets('cannot buy without enough coins', (tester) async {
    final container = await _pumpShop(tester, coins: 100);
    await tester.tap(_offer('booster_hint', 'offer_single'));
    await tester.pump();

    final profile = container.read(profileControllerProvider).value!;
    expect(profile.coins, 100);
    expect(profile.hintTokens, 0);
    expect(find.text('Nicht genug Münzen'), findsOneWidget);
  });

  test('bundle price falls back to the per-item price for other amounts', () {
    const price = BoosterPrice(single: 100, bundle: 250);
    expect(price.forAmount(1), 100);
    expect(price.forAmount(EconomyConfig.boosterBundleSize), 250);
  });
}
