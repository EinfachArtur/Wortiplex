import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../state/profile_providers.dart';
import 'coin_icon.dart';

class CoinHud extends ConsumerWidget {
  final VoidCallback onAddPressed;

  const CoinHud({super.key, required this.onAddPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final coins = profile.valueOrNull?.coins ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinIcon(size: 22),
          const SizedBox(width: 4),
          Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          InkWell(
            onTap: onAddPressed,
            borderRadius: BorderRadius.circular(12),
            child: const CircleAvatar(
              radius: 11,
              backgroundColor: AppColors.correct,
              child: Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
