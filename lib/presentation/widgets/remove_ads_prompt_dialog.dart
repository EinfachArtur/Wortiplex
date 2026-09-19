import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/economy_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/navigation/navigator_key.dart';
import '../../core/theme/game_style.dart';
import '../state/ads_providers.dart';

/// Shown right after an ad clip has closed: "Fed up with ads? Go ad-free for
/// X". The price is the store's localized price when it can be fetched and a
/// configured fallback otherwise.
class RemoveAdsPromptDialog extends ConsumerStatefulWidget {
  const RemoveAdsPromptDialog({super.key});

  /// Opens the dialog on top of the current screen. Does nothing if the app
  /// has no navigator yet.
  static Future<void> show() async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'RemoveAdsPrompt',
      barrierColor: const Color(0xFF0B0724).withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, _, _) => const RemoveAdsPromptDialog(),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(scale: curved, child: FadeTransition(opacity: anim, child: child));
      },
    );
  }

  @override
  ConsumerState<RemoveAdsPromptDialog> createState() => _RemoveAdsPromptDialogState();
}

class _RemoveAdsPromptDialogState extends ConsumerState<RemoveAdsPromptDialog> {
  String _price = EconomyConfig.removeAdsFallbackPrice;

  @override
  void initState() {
    super.initState();
    unawaited(_loadStorePrice());
  }

  Future<void> _loadStorePrice() async {
    try {
      final rc = ref.read(revenueCatServiceProvider);
      final products = await rc.queryProducts({EconomyConfig.removeAdsProductId}).timeout(const Duration(seconds: 3));
      if (products.isNotEmpty && mounted) {
        setState(() => _price = products.first.priceString);
      }
    } catch (_) {
      // No store (emulator, offline): keep the fallback price.
    }
  }

  Future<void> _buy() async {
    final rc = ref.read(revenueCatServiceProvider);
    Navigator.of(context).pop();
    // The purchase listener applies the result; nothing else to do here.
    await rc.buyNonConsumable(EconomyConfig.removeAdsProductId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3B2A8C), Color(0xFF221860)]),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: GameColors.mint, width: 2.5),
            boxShadow: [BoxShadow(color: GameColors.mint.withValues(alpha: 0.3), blurRadius: 40)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _NoAdsImage(),
              const SizedBox(height: 16),
              GameText(l10n.removeAdsPromptTitle, size: 26),
              const SizedBox(height: 8),
              GameText(l10n.removeAdsPromptBody, size: 15, color: GameColors.textDim, shadow: null, weight: 500),
              const SizedBox(height: 14),
              _Bullet(l10n.subBenefitNoAds),
              _Bullet(l10n.removeAdsPromptOnce),
              const SizedBox(height: 20),
              ChunkyButton(
                key: const ValueKey('remove_ads_buy'),
                width: double.infinity,
                height: 60,
                onPressed: _buy,
                child: GameText(l10n.removeAdsPromptBuy(_price), size: 19, color: GameColors.night0, shadow: null),
              ),
              const SizedBox(height: 4),
              TextButton(
                key: const ValueKey('remove_ads_later'),
                onPressed: () => Navigator.of(context).pop(),
                child: GameText(l10n.removeAdsPromptLater, size: 15, color: GameColors.textDim, shadow: null, weight: 600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "NO ADS" artwork with a soft mint glow behind it.
class _NoAdsImage extends StatelessWidget {
  const _NoAdsImage();

  static const assetPath = 'assets/images/no_ads.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: GameColors.mint.withValues(alpha: 0.5), blurRadius: 26)],
      ),
      child: Image.asset(assetPath, fit: BoxFit.contain),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(color: GameColors.mint, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 15, color: GameColors.night0),
          ),
          const SizedBox(width: 10),
          Expanded(child: GameText(text, size: 14, textAlign: TextAlign.left, shadow: null, weight: 600)),
        ],
      ),
    );
  }
}
