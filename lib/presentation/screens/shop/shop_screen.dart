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
import '../../widgets/remove_ads_prompt_dialog.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _watchingAd = false;

  Future<void> _watchAdForCoins() async {
    final profile = ref.read(profileControllerProvider).valueOrNull;
    if (profile == null || !profile.canWatchRewardedAd) {
      final cd = profile?.rewardedAdCooldownRemaining;
      final mins = cd != null ? cd.inMinutes + 1 : 60;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('Limit erreicht (5 Videos/Std.). Wieder verfügbar in $mins Min.'),
          ),
        );
      return;
    }

    setState(() => _watchingAd = true);
    final ads = ref.read(adsServiceProvider);
    await ads.loadRewarded();
    final earned = await ads.showRewardedIfReady(onReward: (amount) {});
    if (earned) {
      await ref
          .read(profileControllerProvider.notifier)
          .recordRewardedAdWatched();
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

  Future<void> _buyRemoveAds() => RemoveAdsPromptDialog.show();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final packages = EconomyConfig.coinPackages;
    final profile = ref.watch(profileControllerProvider).valueOrNull;

    final canWatchAd = profile?.canWatchRewardedAd ?? true;
    final remainingAds = profile?.remainingRewardedAds ?? 5;
    final cooldown = profile?.rewardedAdCooldownRemaining;
    final cooldownMins = cooldown != null ? cooldown.inMinutes + 1 : 0;

    return GameScaffold(
      title: l10n.shop,
      onCoinsTap: () {},
      body: Scrollbar(
        thumbVisibility: true,
        radius: const Radius.circular(8),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 32),
          children: [
            if (profile == null || !profile.subscription.isAdFree)
              _RowTile(
                imageAsset: 'assets/images/no_ads.png',
                title: l10n.removeAds,
                trailing: const Icon(Icons.chevron_right_rounded, color: GameColors.textDim, size: 24),
                onTap: _buyRemoveAds,
              ),
            _RowTile(
              imageAsset: 'assets/images/coin.png',
              title: l10n.watchAdFor20Coins,
              trailing: _watchingAd
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: GameColors.mint))
                  : _CoinChip(
                      amount: EconomyConfig.rewardedAdCoins,
                      badge: canWatchAd ? '($remainingAds/5)' : 'Noch ${cooldownMins}m',
                      disabled: !canWatchAd,
                    ),
              onTap: _watchingAd ? null : _watchAdForCoins,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                GameText(l10n.coins, size: 16, textAlign: TextAlign.left, shadow: null),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 14, color: GameColors.textDim),
                    const SizedBox(width: 4),
                    GameText('Booster & mehr unten', size: 12, color: GameColors.textDim, shadow: null, weight: 600),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
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
            const SizedBox(height: 18),
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
            const SizedBox(height: 14),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: GameText(title.toUpperCase(), size: 15, textAlign: TextAlign.left, shadow: null)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: GameColors.pill, borderRadius: BorderRadius.circular(12)),
                  child: GameText(l10n.boosterOwned(owned), size: 11, color: GameColors.textDim, shadow: null, weight: 600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _BoosterOffer(
                    key: const ValueKey('offer_single'),
                    label: l10n.boosterGet(1),
                    asset: singleAsset,
                    imageSize: 52,
                    cost: price.single,
                    onTap: () => onBuy(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BoosterOffer(
                    key: const ValueKey('offer_bundle'),
                    label: l10n.boosterGet(bundle),
                    asset: bundleAsset,
                    imageSize: 62,
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
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
        decoration: BoxDecoration(
          color: GameColors.night0.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ribbon != null ? GameColors.amber.withValues(alpha: 0.7) : GameColors.glassBorder),
        ),
        child: Column(
          children: [
            GameText(label, size: 14, color: GameColors.amber, shadow: null),
            const SizedBox(height: 4),
            SizedBox(height: 60, child: Center(child: Image.asset(asset, width: imageSize, height: imageSize, fit: BoxFit.contain))),
            const SizedBox(height: 2),
            SizedBox(
              height: 16,
              child: ribbon == null
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(color: GameColors.coral, borderRadius: BorderRadius.circular(6)),
                      child: Center(child: GameText(ribbon!, size: 10, shadow: null)),
                    ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
              decoration: BoxDecoration(color: GameColors.mint, borderRadius: BorderRadius.circular(14)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CoinIcon(size: 18),
                  const SizedBox(width: 5),
                  GameText('$cost', size: 15, color: GameColors.night0, shadow: null),
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
  final String? badge;
  final bool disabled;
  const _CoinChip({required this.amount, this.badge, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: disabled ? GameColors.night0.withValues(alpha: 0.45) : GameColors.pill,
        borderRadius: BorderRadius.circular(16),
        border: disabled ? Border.all(color: GameColors.glassBorder) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinIcon(size: 18),
          const SizedBox(width: 5),
          GameText('+$amount', size: 14, color: disabled ? GameColors.textDim : Colors.white, shadow: null),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: disabled ? GameColors.coral.withValues(alpha: 0.25) : GameColors.mint.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GameText(
                badge!,
                size: 11,
                color: disabled ? GameColors.coral : GameColors.mint,
                shadow: null,
                weight: 600,
              ),
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: GameColors.glass,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlight ? (color ?? GameColors.violet) : GameColors.glassBorder,
              width: highlight ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              if (imageAsset != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    imageAsset!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                )
              else if (icon != null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: color ?? GameColors.sky,
                  ),
                  child: Icon(icon, color: GameColors.night0, size: 22),
                ),
              const SizedBox(width: 10),
              Expanded(child: GameText(title, size: 15, textAlign: TextAlign.left, shadow: null, weight: 700)),
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
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
              radius: 18,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    imageAsset,
                    height: 36,
                    width: 36,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 3),
                  GameText('$coins', size: 17, shadow: null),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: GameColors.mint, borderRadius: BorderRadius.circular(10)),
                    child: GameText(price, size: 12, color: GameColors.night0, shadow: null, weight: 700),
                  ),
                ],
              ),
            ),
          ),
          if (badge case final badge?)
            Positioned(
              top: -7,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: GameColors.amber, borderRadius: BorderRadius.circular(8)),
                  child: GameText(badge.toUpperCase(), size: 9, color: GameColors.night0, shadow: null, weight: 700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
