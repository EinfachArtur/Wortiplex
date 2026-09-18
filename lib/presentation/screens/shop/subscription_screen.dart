import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/economy_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/subscription_status.dart';
import '../../state/ads_providers.dart';
import '../../state/profile_providers.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(profileControllerProvider);
    final subscription = profileAsync.valueOrNull?.subscription ?? const SubscriptionStatus();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscriptionTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (subscription.isActive)
            Card(
              color: Colors.green.shade50,
              child: ListTile(
                leading: const Icon(Icons.verified, color: Colors.green),
                title: Text('${l10n.subscriptionTitle} ${subscription.tier == SubscriptionTier.yearly ? "(Yearly)" : "(Monthly)"}'),
                subtitle: subscription.expiresAt != null
                    ? Text('Renews ${subscription.expiresAt!.toLocal().toString().split(' ').first}')
                    : null,
              ),
            )
          else ...[
            const _BenefitsList(),
            const SizedBox(height: 20),
            _PlanCard(
              title: 'Monthly',
              price: '4,99 €',
              onTap: () => ref.read(iapServiceProvider).buyNonConsumable(EconomyConfig.subscriptionMonthlyId),
            ),
            const SizedBox(height: 10),
            _PlanCard(
              title: 'Yearly',
              price: '39,99 €',
              badge: 'Best value',
              onTap: () => ref.read(iapServiceProvider).buyNonConsumable(EconomyConfig.subscriptionYearlyId),
            ),
          ],
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => ref.read(iapServiceProvider).restorePurchases(),
            child: Text(l10n.restorePurchases),
          ),
        ],
      ),
    );
  }
}

class _BenefitsList extends StatelessWidget {
  const _BenefitsList();

  @override
  Widget build(BuildContext context) {
    const benefits = [
      'No ads, ever',
      'Daily coin bonus, no video required',
      'Discount on hints & letter strikeouts',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final b in benefits)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(b)),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String? badge;
  final VoidCallback onTap;

  const _PlanCard({required this.title, required this.price, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(price),
        trailing: badge != null
            ? Chip(label: Text(badge!), backgroundColor: Colors.deepOrange.shade100)
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
