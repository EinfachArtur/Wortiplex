import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/economy_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/game_style.dart';
import '../../../domain/economy/coin_transaction.dart';
import '../../state/ads_providers.dart';
import '../../state/profile_providers.dart';
import '../../widgets/coin_icon.dart';
import '../../widgets/game_scaffold.dart';
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

  // Coins are credited by the app-wide purchase listener once the store
  // reports the purchase as successful.
  Future<void> _buyPackage(String productId) => ref.read(iapServiceProvider).buyConsumable(productId);

  Future<void> _buyRemoveAds() => ref.read(iapServiceProvider).buyNonConsumable(EconomyConfig.removeAdsProductId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final packages = EconomyConfig.coinPackages;

    return GameScaffold(
      title: l10n.shop,
      onCoinsTap: () {},
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _RowTile(
            icon: Icons.play_arrow_rounded,
            color: GameColors.coral,
            title: l10n.watchAdFor20Coins,
            trailing: _watchingAd
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: GameColors.mint))
                : _CoinChip(amount: EconomyConfig.rewardedAdCoins),
            onTap: _watchingAd ? null : _watchAdForCoins,
          ),
          const SizedBox(height: 22),
          GameText(l10n.coins, size: 18, textAlign: TextAlign.left, shadow: null),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.98,
            children: [
              for (var i = 0; i < packages.length; i++)
                _PackageCard(
                  coins: packages[i].coins,
                  price: packages[i].priceLabel,
                  iconSize: 40.0 + i * 4,
                  badge: switch (packages[i].badge) {
                    PackageBadge.mostPopular => l10n.mostPopular,
                    PackageBadge.bestValue => l10n.bestValue,
                    PackageBadge.none => null,
                  },
                  onTap: () => _buyPackage(packages[i].productId),
                ),
            ],
          ),
          const SizedBox(height: 22),
          _RowTile(
            icon: Icons.workspace_premium_rounded,
            color: GameColors.violet,
            title: l10n.subscriptionTitle,
            highlight: true,
            trailing: const Icon(Icons.chevron_right_rounded, color: GameColors.textDim, size: 28),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
          ),
          _RowTile(
            icon: Icons.block_rounded,
            color: GameColors.sky,
            title: l10n.removeAds,
            trailing: const Icon(Icons.chevron_right_rounded, color: GameColors.textDim, size: 28),
            onTap: _buyRemoveAds,
          ),
          _RowTile(
            icon: Icons.restore_rounded,
            color: GameColors.slate,
            title: l10n.restorePurchases,
            onTap: () => ref.read(iapServiceProvider).restorePurchases(),
          ),
        ],
      ),
    );
  }
}

class _CoinChip extends StatelessWidget {
  final int amount;
  const _CoinChip({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
      decoration: BoxDecoration(color: GameColors.pill, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinIcon(size: 20),
          const SizedBox(width: 6),
          GameText('+$amount', size: 15, shadow: null),
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool highlight;

  const _RowTile({required this.icon, required this.color, required this.title, this.trailing, this.onTap, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GameColors.glass,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: highlight ? color : GameColors.glassBorder, width: highlight ? 1.8 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: color),
                child: Icon(icon, color: GameColors.night0, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(child: GameText(title, size: 16, textAlign: TextAlign.left, shadow: null, weight: 700)),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final int coins;
  final String price;
  final double iconSize;
  final String? badge;
  final VoidCallback onTap;

  const _PackageCard({required this.coins, required this.price, required this.iconSize, required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(10, 18, 10, 12),
              radius: 24,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CoinIcon(size: iconSize),
                  const SizedBox(height: 10),
                  GameText('$coins', size: 24, shadow: null),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(color: GameColors.mint, borderRadius: BorderRadius.circular(16)),
                    child: GameText(price, size: 15, color: GameColors.night0, shadow: null),
                  ),
                ],
              ),
            ),
          ),
          if (badge case final badge?)
            Positioned(
              top: -9,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: GameColors.amber, borderRadius: BorderRadius.circular(10)),
                  child: GameText(badge!.toUpperCase(), size: 10, color: GameColors.night0, shadow: null),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
