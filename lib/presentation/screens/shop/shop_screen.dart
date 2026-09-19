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

  Future<void> _buyBooster(BoosterKind kind, int amount) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(profileControllerProvider.notifier).buyBooster(kind, amount);
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(ok ? l10n.boosterBought : l10n.notEnoughCoins)));
  }

  Future<void> _buyRemoveAds() => ref.read(iapServiceProvider).buyNonConsumable(EconomyConfig.removeAdsProductId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final packages = EconomyConfig.coinPackages;
    final profile = ref.watch(profileControllerProvider).valueOrNull;

    return GameScaffold(
      title: l10n.shop,
      onCoinsTap: () {},
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (profile == null || !profile.subscription.isAdFree)
            _RowTile(
              imageAsset: 'assets/images/no_ads.png',
              title: l10n.removeAds,
              trailing: const Icon(Icons.chevron_right_rounded, color: GameColors.textDim, size: 28),
              onTap: _buyRemoveAds,
            ),
          _RowTile(
            imageAsset: 'assets/images/coin.png',
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
                  imageAsset: 'assets/images/coins_pack_${i + 1}.png',
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
          _BoosterSection(
            key: const ValueKey('booster_hint'),
            title: l10n.boosterHintTitle,
            singleAsset: 'assets/images/glühbirne_1.png',
            bundleAsset: 'assets/images/glühbirne_2.png',
            owned: profile?.hintTokens ?? 0,
            price: EconomyConfig.boosterPrices[BoosterKind.hint]!,
            onBuy: (amount) => _buyBooster(BoosterKind.hint, amount),
          ),
          _BoosterSection(
            key: const ValueKey('booster_strikeout'),
            title: l10n.boosterStrikeoutTitle,
            singleAsset: 'assets/images/fadenkreuz_1.png',
            bundleAsset: 'assets/images/fadenkreuz_2.png',
            owned: profile?.strikeoutTokens ?? 0,
            price: EconomyConfig.boosterPrices[BoosterKind.strikeout]!,
            onBuy: (amount) => _buyBooster(BoosterKind.strikeout, amount),
          ),
          _BoosterSection(
            key: const ValueKey('booster_skip'),
            title: l10n.boosterSkipTitle,
            singleAsset: 'assets/images/Skip_1.png',
            bundleAsset: 'assets/images/Skip_2.png',
            owned: profile?.skipsAvailable ?? 0,
            price: EconomyConfig.boosterPrices[BoosterKind.skip]!,
            onBuy: (amount) => _buyBooster(BoosterKind.skip, amount),
          ),
          const SizedBox(height: 22),
          _RowTile(
            icon: Icons.restore_rounded,
            color: GameColors.slate,
            title: l10n.restorePurchases,
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final rc = ref.read(revenueCatServiceProvider);
              final info = await rc.restorePurchases();
              final hasActive = info?.entitlements.active.isNotEmpty ?? false;
              messenger
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text(hasActive ? l10n.subscriptionActive : 'Keine aktiven Käufe gefunden.'),
                  ),
                );
            },
          ),
        ],
      ),
    );
  }
}

/// One booster type: a title with the current stock and two offers, a single
/// item and a discounted bundle of [EconomyConfig.boosterBundleSize].
class _BoosterSection extends StatelessWidget {
  final String title;
  final String singleAsset;
  final String bundleAsset;
  final int owned;
  final BoosterPrice price;
  final void Function(int amount) onBuy;

  const _BoosterSection({
    super.key,
    required this.title,
    required this.singleAsset,
    required this.bundleAsset,
    required this.owned,
    required this.price,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const bundle = EconomyConfig.boosterBundleSize;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        radius: 26,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: GameText(title.toUpperCase(), size: 16, textAlign: TextAlign.left, shadow: null)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: GameColors.pill, borderRadius: BorderRadius.circular(14)),
                  child: GameText(l10n.boosterOwned(owned), size: 12, color: GameColors.textDim, shadow: null, weight: 600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _BoosterOffer(
                    key: const ValueKey('offer_single'),
                    label: l10n.boosterGet(1),
                    asset: singleAsset,
                    imageSize: 64,
                    cost: price.single,
                    onTap: () => onBuy(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BoosterOffer(
                    key: const ValueKey('offer_bundle'),
                    label: l10n.boosterGet(bundle),
                    asset: bundleAsset,
                    imageSize: 76,
                    cost: price.bundle,
                    ribbon: l10n.bestValue,
                    onTap: () => onBuy(bundle),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BoosterOffer extends StatelessWidget {
  final String label;
  final String asset;
  final double imageSize;
  final int cost;
  final String? ribbon;
  final VoidCallback onTap;

  const _BoosterOffer({
    super.key,
    required this.label,
    required this.asset,
    required this.imageSize,
    required this.cost,
    required this.onTap,
    this.ribbon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        decoration: BoxDecoration(
          color: GameColors.night0.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ribbon != null ? GameColors.amber.withValues(alpha: 0.7) : GameColors.glassBorder),
        ),
        child: Column(
          children: [
            GameText(label, size: 15, color: GameColors.amber, shadow: null),
            const SizedBox(height: 6),
            SizedBox(height: 80, child: Center(child: Image.asset(asset, width: imageSize, height: imageSize, fit: BoxFit.contain))),
            const SizedBox(height: 4),
            SizedBox(
              height: 18,
              child: ribbon == null
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(color: GameColors.coral, borderRadius: BorderRadius.circular(6)),
                      child: Center(child: GameText(ribbon!, size: 11, shadow: null)),
                    ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 5, 14, 5),
              decoration: BoxDecoration(color: GameColors.mint, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CoinIcon(size: 22),
                  const SizedBox(width: 6),
                  GameText('$cost', size: 17, color: GameColors.night0, shadow: null),
                ],
              ),
            ),
          ],
        ),
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
  final IconData? icon;
  final String? imageAsset;
  final Color? color;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool highlight;

  const _RowTile({
    this.icon,
    this.imageAsset,
    this.color,
    required this.title,
    this.trailing,
    this.onTap,
    this.highlight = false,
  });

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
            border: Border.all(
              color: highlight ? (color ?? GameColors.violet) : GameColors.glassBorder,
              width: highlight ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              if (imageAsset != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    imageAsset!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                )
              else if (icon != null)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: color ?? GameColors.sky,
                  ),
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
  final String imageAsset;
  final String? badge;
  final VoidCallback onTap;

  const _PackageCard({
    required this.coins,
    required this.price,
    required this.imageAsset,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
              radius: 24,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    imageAsset,
                    height: 52,
                    width: 52,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  GameText('$coins', size: 22, shadow: null),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: GameColors.mint, borderRadius: BorderRadius.circular(16)),
                    child: GameText(price, size: 14, color: GameColors.night0, shadow: null),
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
                  child: GameText(badge.toUpperCase(), size: 10, color: GameColors.night0, shadow: null),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
