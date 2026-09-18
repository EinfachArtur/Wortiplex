import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/game_mode.dart';
import '../../state/profile_providers.dart';
import '../../widgets/coin_hud.dart';
import '../../widgets/daily_rewards_card.dart';
import '../daily/daily_puzzle_screen.dart';
import '../game_board/game_board_screen.dart';
import '../settings/settings_screen.dart';
import '../shop/shop_screen.dart';
import '../stats/stats_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: CoinHud(
                onAddPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ShopScreen()),
                ),
              ),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const DailyRewardsCard(),
            const SizedBox(height: 16),
            _ModeTile(
              icon: Icons.grid_on,
              title: l10n.menuClassic,
              subtitle: '${l10n.currentStreak}: ${profile.statsFor('classic', profile.language).currentStreak}',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GameBoardScreen(mode: GameMode.classic)),
              ),
            ),
            _ModeTile(
              icon: Icons.today,
              title: l10n.menuDaily,
              subtitle: _dateLabel(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DailyPuzzleScreen()),
              ),
            ),
            _ModeTile(
              icon: Icons.bolt,
              title: l10n.menuWordFever,
              subtitle: l10n.comingSoon,
              onTap: null,
            ),
            _ModeTile(
              icon: Icons.lock_outline,
              title: l10n.menuSecretWord,
              subtitle: l10n.comingSoon,
              onTap: null,
            ),
            _ModeTile(
              icon: Icons.group,
              title: l10n.menuTogether,
              subtitle: l10n.comingSoon,
              onTap: null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShopScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel() {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}';
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ModeTile({required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: disabled ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
        enabled: !disabled,
      ),
    );
  }
}
