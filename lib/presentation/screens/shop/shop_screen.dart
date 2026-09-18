import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/economy_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/economy/coin_transaction.dart';
import '../../state/ads_providers.dart';
import '../../state/profile_providers.dart';
import '../../widgets/coin_hud.dart';
import 'subscription_screen.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _watchingAd = false;

  Future<void> _watchAdForCoins() async {
    setState(() => _watchingAd = true);
    final ads = ref.read(adsServiceProvider);
    await ads.loadRewarded();
    final earned = await ads.showRewardedIfReady(onReward: (amount) {});
    if (earned) {
      await ref
          .read(profileControllerProvider.notifier)
          .earnCoins(EconomyConfig.rewardedAdCoins, CoinTransactionReason.adReward);
    }
    if (mounted) setState(() => _watchingAd = false);
  }

  Future<void> _buyPackage(String productId) async {
    // MVP wiring: initiates the store purchase flow. Crediting coins happens
    // when InAppPurchaseService.purchaseStream reports success (see TODO in
    // app-level purchase listener for Etappe 2 completion).
    final iap = ref.read(iapServiceProvider);
    await iap.buyConsumable(productId);
  }

  Future<void> _buyRemoveAds() async {
    final iap = ref.read(iapServiceProvider);
    await iap.buyNonConsumable(EconomyConfig.removeAdsProductId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shop),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: CoinHud(onAddPressed: () {})),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.amber.shade50,
            child: ListTile(
              leading: const Icon(Icons.play_circle_fill, color: Colors.deepOrange),
              title: Text(l10n.watchAdFor20Coins),
              trailing: _watchingAd
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right),
              onTap: _watchingAd ? null : _watchAdForCoins,
            ),
          ),
          const SizedBox(height: 16),
          Text('Coins', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              for (final pkg in EconomyConfig.coinPackages)
                _CoinPackageCard(
                  coins: pkg.coins,
                  priceLabel: pkg.priceLabel,
                  badgeLabel: switch (pkg.badge) {
                    PackageBadge.mostPopular => l10n.mostPopular,
                    PackageBadge.bestValue => l10n.bestValue,
                    PackageBadge.none => null,
                  },
                  onTap: () => _buyPackage(pkg.productId),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.deepPurple),
              title: Text(l10n.subscriptionTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.block),
              title: Text(l10n.removeAds),
              trailing: const Icon(Icons.chevron_right),
              onTap: _buyRemoveAds,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restore),
              title: Text(l10n.restorePurchases),
              onTap: () => ref.read(iapServiceProvider).restorePurchases(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinPackageCard extends StatelessWidget {
  final int coins;
  final String priceLabel;
  final String? badgeLabel;
  final VoidCallback onTap;

  const _CoinPackageCard({
    required this.coins,
    required this.priceLabel,
    required this.badgeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, size: 28, color: Colors.amber),
                  const SizedBox(height: 4),
                  Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(priceLabel, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (badgeLabel != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badgeLabel!, style: const TextStyle(color: Colors.white, fontSize: 9)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
