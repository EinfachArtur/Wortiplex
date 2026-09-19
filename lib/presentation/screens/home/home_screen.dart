import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/game_style.dart';
import '../../../domain/models/game_mode.dart';
import '../../state/profile_providers.dart';
import '../../widgets/daily_rewards_card.dart';
import '../../widgets/game_scaffold.dart';
import '../daily/daily_puzzle_screen.dart';
import '../game_board/game_board_screen.dart';
import '../settings/settings_screen.dart';
import '../shop/shop_screen.dart';
import '../stats/stats_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final profile = ref.watch(profileControllerProvider).valueOrNull;

    final streak = profile?.statsFor('classic', profile.language).currentStreak ?? 0;
    final dailyDone = profile != null && profile.dailyHistory.hasPlayed(profile.language, DateTime.now());

    return GameScaffold(
      showBack: false,
      titleWidget: const _Logo(),
      bottom: _BottomBar(
        items: [
          _NavItem(Icons.shopping_bag_rounded, l10n.shop, () => _open(context, const ShopScreen())),
          _NavItem(Icons.bar_chart_rounded, l10n.statistics, () => _open(context, const StatsScreen())),
          _NavItem(Icons.settings_rounded, l10n.settings, () => _open(context, const SettingsScreen())),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                const DailyRewardsCard(),
                const SizedBox(height: 18),
                _ModeCard(
                  icon: Icons.grid_view_rounded,
                  color: GameColors.mint,
                  title: l10n.menuClassic,
                  subtitle: '${l10n.currentStreak}: $streak',
                  trailing: streak > 0 ? _Chip(icon: Icons.local_fire_department_rounded, label: '$streak', color: GameColors.amber) : null,
                  onTap: () => _open(context, const GameBoardScreen(mode: GameMode.classic)),
                ),
                _ModeCard(
                  icon: Icons.calendar_month_rounded,
                  color: GameColors.amber,
                  title: l10n.menuDaily,
                  subtitle: DateFormat.MMMd(locale).format(DateTime.now()),
                  trailing: dailyDone ? const _Chip(icon: Icons.check_rounded, label: '', color: GameColors.mint) : null,
                  onTap: () => _open(context, const DailyPuzzleScreen()),
                ),
                _ModeCard(
                  icon: Icons.bolt_rounded,
                  color: GameColors.coral,
                  title: l10n.menuWordFever,
                  subtitle: l10n.comingSoon,
                ),
                _ModeCard(
                  icon: Icons.lock_rounded,
                  color: GameColors.violet,
                  title: l10n.menuSecretWord,
                  subtitle: l10n.comingSoon,
                ),
                _ModeCard(
                  icon: Icons.groups_rounded,
                  color: GameColors.sky,
                  title: l10n.menuTogether,
                  subtitle: l10n.comingSoon,
                ),
              ],
            ),
    );
  }
}

/// Wordmark: the logo image plus the name.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/logo.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        const SizedBox(width: 10),
        const GameText('WortiPlex', size: 26),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ModeCard({required this.icon, required this.color, required this.title, required this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            radius: 26,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(color, Colors.white, 0.25)!, color]),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Icon(icon, color: GameColors.night0, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GameText(title, size: 19, textAlign: TextAlign.left, shadow: null),
                      const SizedBox(height: 3),
                      GameText(subtitle, size: 13, color: GameColors.textDim, textAlign: TextAlign.left, shadow: null, weight: 500),
                    ],
                  ),
                ),
                if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
                if (enabled) const Icon(Icons.chevron_right_rounded, color: GameColors.textDim, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          if (label.isNotEmpty) ...[const SizedBox(width: 4), GameText(label, size: 15, color: color, shadow: null)],
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavItem(this.icon, this.label, this.onTap);
}

/// Floating glass navigation bar.
class _BottomBar extends StatelessWidget {
  final List<_NavItem> items;
  const _BottomBar({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: GameColors.pill,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: GameColors.glassBorder),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: item.onTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: Colors.white, size: 26),
                    const SizedBox(height: 2),
                    GameText(item.label, size: 11, color: GameColors.textDim, shadow: null, weight: 600),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
