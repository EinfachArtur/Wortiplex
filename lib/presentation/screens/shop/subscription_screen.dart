import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/config/economy_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/game_style.dart';
import '../../../domain/models/subscription_status.dart';
import '../../state/ads_providers.dart';
import '../../state/profile_providers.dart';
import '../../widgets/game_scaffold.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isRestoring = false;

  Future<void> _restorePurchases() async {
    setState(() => _isRestoring = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final rc = ref.read(revenueCatServiceProvider);

    final info = await rc.restorePurchases();
    if (mounted) {
      setState(() => _isRestoring = false);
      final hasActive = info?.entitlements.active.isNotEmpty ?? false;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(hasActive ? l10n.subscriptionActive : 'Keine aktiven Käufe gefunden.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final subscription = ref.watch(profileControllerProvider).valueOrNull?.subscription ?? const SubscriptionStatus();
    final rc = ref.read(revenueCatServiceProvider);
    final offeringsAsync = ref.watch(offeringsProvider);

    // Dynamische Pakete aus RevenueCat Offerings ermitteln
    Package? monthlyPackage;
    Package? yearlyPackage;
    final offerings = offeringsAsync.valueOrNull;

    if (offerings?.current != null) {
      monthlyPackage = offerings!.current!.monthly;
      yearlyPackage = offerings.current!.annual;
    }

    final yearlyPrice = yearlyPackage?.storeProduct.priceString ?? '39,99 €';
    final monthlyPrice = monthlyPackage?.storeProduct.priceString ?? '4,99 €';

    return GameScaffold(
      title: l10n.subscriptionTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C4DF0), Color(0xFF3B2A8C)],
              ),
              border: Border.all(color: GameColors.amber, width: 2),
              boxShadow: [BoxShadow(color: GameColors.violet.withValues(alpha: 0.4), blurRadius: 24)],
            ),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: GameColors.amber, size: 64),
                const SizedBox(height: 6),
                GameText(l10n.subscriptionTitle, size: 30),
                const SizedBox(height: 16),
                _Benefit(l10n.subBenefitNoAds),
                _Benefit(l10n.subBenefitBonus),
                _Benefit(l10n.subBenefitDiscount),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (subscription.isActive)
            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: GameColors.mint, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GameText(
                          '${subscription.tier == SubscriptionTier.yearly ? l10n.planYearly : l10n.planMonthly} · ${l10n.subscriptionActive}',
                          size: 16,
                          textAlign: TextAlign.left,
                          shadow: null,
                        ),
                        if (subscription.expiresAt != null)
                          GameText(
                            l10n.subscriptionRenews(DateFormat.yMMMd(locale).format(subscription.expiresAt!.toLocal())),
                            size: 13,
                            color: GameColors.textDim,
                            textAlign: TextAlign.left,
                            shadow: null,
                            weight: 500,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _Plan(
              title: l10n.planYearly,
              price: yearlyPrice,
              badge: l10n.bestValue,
              onTap: () {
                if (yearlyPackage != null) {
                  rc.purchasePackage(yearlyPackage);
                } else {
                  rc.buyNonConsumable(EconomyConfig.subscriptionYearlyId);
                }
              },
            ),
            const SizedBox(height: 12),
            _Plan(
              title: l10n.planMonthly,
              price: monthlyPrice,
              onTap: () {
                if (monthlyPackage != null) {
                  rc.purchasePackage(monthlyPackage);
                } else {
                  rc.buyNonConsumable(EconomyConfig.subscriptionMonthlyId);
                }
              },
            ),
          ],
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: _isRestoring ? null : _restorePurchases,
              child: _isRestoring
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: GameColors.textDim),
                    )
                  : GameText(l10n.restorePurchases, size: 15, color: GameColors.textDim, shadow: null, weight: 600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String text;
  const _Benefit(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: GameColors.mint, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 16, color: GameColors.night0),
          ),
          const SizedBox(width: 12),
          Expanded(child: GameText(text, size: 15, textAlign: TextAlign.left, shadow: null, weight: 600)),
        ],
      ),
    );
  }
}

class _Plan extends StatelessWidget {
  final String title;
  final String price;
  final String? badge;
  final VoidCallback onTap;

  const _Plan({required this.title, required this.price, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GameColors.glass,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: badge != null ? GameColors.amber : GameColors.glassBorder,
            width: badge != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GameText(title, size: 18, textAlign: TextAlign.left, shadow: null),
                  if (badge != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: GameColors.amber, borderRadius: BorderRadius.circular(8)),
                      child: GameText(badge!.toUpperCase(), size: 10, color: GameColors.night0, shadow: null),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(color: GameColors.mint, borderRadius: BorderRadius.circular(18)),
              child: GameText(price, size: 17, color: GameColors.night0, shadow: null),
            ),
          ],
        ),
      ),
    );
  }
}
