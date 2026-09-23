import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

import '../../../core/config/date_guess_config.dart';
import '../../../core/config/word_fever_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/game_style.dart';
import '../../../domain/models/game_mode.dart';
import '../../state/ads_providers.dart';
import '../../state/profile_providers.dart';
import '../../widgets/daily_rewards_card.dart';
import '../../widgets/game_pills.dart';
import '../../widgets/game_scaffold.dart';
import '../../widgets/wordmark_tiles.dart';
import '../daily/daily_puzzle_screen.dart';
import '../game_board/game_board_screen.dart';
import '../settings/settings_screen.dart';
import '../shop/shop_screen.dart';
import '../stats/stats_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeLoadBanner();
    });
  }

  void _maybeLoadBanner() {
    final profile = ref.read(profileControllerProvider).valueOrNull;
    if (profile != null && profile.subscription.isAdFree) return;
    if (_bannerAd != null) return;
    final ads = ref.read(adsServiceProvider);
    try {
      final ad = ads.createBannerAd(
        onLoaded: () {
          if (mounted) setState(() {});
        },
        onFailed: () {
          if (mounted) {
            setState(() => _bannerAd = null);
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) _maybeLoadBanner();
            });
          }
        },
      );
      setState(() => _bannerAd = ad);
    } catch (_) {}
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _open(BuildContext context, Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.valueOrNull;

    final streak = profile?.statsFor('classic', profile.language).currentStreak ?? 0;
    final dateGuessStreak = profile?.statsFor('dateGuess', profile.language).currentStreak ?? 0;
    final dailyDone = profile != null && profile.dailyHistory.hasPlayed(profile.language, DateTime.now());

    final isAdFree = profile?.subscription.isAdFree ?? false;

    // Show error details instead of infinite loading when something goes wrong
    if (profileState.hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('Fehler beim Laden', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  profileState.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () => ref.invalidate(profileControllerProvider), child: const Text('Erneut versuchen')),
              ],
            ),
          ),
        ),
      );
    }

    return GameScaffold(
      showBack: false,
      titleWidget: Row(children: [if (!isAdFree) const NoAdsButton(), const Spacer()]),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Column(
                children: [
                  Expanded(
                    child: _HomeContent(
                      children: (s) => [
                        _Section(height: 48 * s, child: const WordmarkTiles()),
                        _Section(height: 156 * s, child: const DailyRewardsCard(fill: true)),
                        _Section(
                          height: 84 * s,
                          child: _ModeCard(
                            scale: s,
                            imageAsset: 'assets/images/logo_2.png',
                            color: GameColors.mint,
                            title: l10n.menuClassic,
                            subtitle: '${l10n.currentStreak}: $streak',
                            trailing: streak > 0
                                ? _Chip(icon: Icons.local_fire_department_rounded, label: '$streak', color: GameColors.amber)
                                : null,
                            onTap: () => _open(context, const GameBoardScreen(mode: GameMode.classic)),
                          ),
                        ),
                        _Section(
                          height: 84 * s,
                          child: _ModeCard(
                            scale: s,
                            imageAsset: 'assets/images/kalender.png',
                            color: GameColors.amber,
                            title: l10n.menuDaily,
                            subtitle: DateFormat.MMMd(locale).format(DateTime.now()),
                            trailing: dailyDone ? const _Chip(icon: Icons.check_rounded, label: '', color: GameColors.mint) : null,
                            onTap: () => _open(context, const DailyPuzzleScreen()),
                          ),
                        ),
                        _Section(
                          height: 84 * s,
                          child: _ModeCard(
                            scale: s,
                            imageAsset: 'assets/images/Blitz.png',
                            color: GameColors.coral,
                            title: l10n.menuWordFever,
                            subtitle: l10n.wordFeverDesc(WordFeverConfig.startSeconds),
                            trailing: profile.wordFeverBest > 0
                                ? _Chip(icon: Icons.emoji_events_rounded, label: '${profile.wordFeverBest}', color: GameColors.amber)
                                : null,
                            onTap: () => _open(context, const GameBoardScreen(mode: GameMode.wordFever)),
                          ),
                        ),
                        _Section(
                          height: 84 * s,
                          child: _ModeCard(
                            scale: s,
                            icon: Icons.event_rounded,
                            color: GameColors.sky,
                            title: l10n.menuDateGuess,
                            subtitle: l10n.dateGuessDesc(DateGuessConfig.minYear, DateGuessConfig.maxYear),
                            trailing: dateGuessStreak > 0
                                ? _Chip(icon: Icons.local_fire_department_rounded, label: '$dateGuessStreak', color: GameColors.amber)
                                : null,
                            onTap: () => _open(context, const GameBoardScreen(mode: GameMode.dateGuess)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BottomBar(
                    items: [
                      _NavItem(Icons.shopping_bag_rounded, l10n.shop, () => _open(context, const ShopScreen())),
                      _NavItem(Icons.bar_chart_rounded, l10n.statistics, () => _open(context, const StatsScreen())),
                      _NavItem(Icons.settings_rounded, l10n.settings, () => _open(context, const SettingsScreen())),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (!isAdFree)
                    Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: _bannerAd != null
                          ? SizedBox(
                              height: _bannerAd!.size.height.toDouble(),
                              width: _bannerAd!.size.width.toDouble(),
                              child: AdWidget(ad: _bannerAd!),
                            )
                          : const SizedBox(height: 50),
                    ),
                ],
              ),
            ),
    );
  }
}

/// One block of the home screen with a fixed height. The first two blocks
/// (name and daily rewards) are separated from the game modes by more space
/// than the modes are from each other.
class _Section {
  final double height;
  final Widget child;
  const _Section({required this.height, required this.child});
}

/// Lays the sections out at their natural size, scales them up a little on
/// tall screens, and spreads whatever space is still left between the groups,
/// so the screen never ends up with one huge empty area. Very short screens
/// scroll instead.
class _HomeContent extends StatelessWidget {
  /// Builds the sections for a size factor (1.0 = base size).
  final List<_Section> Function(double scale) children;
  const _HomeContent({required this.children});

  static const _minScale = 0.9;
  static const _maxScale = 1.3;
  static const _modeGap = 12.0;
  static const _groupGap = 18.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sections are: name, daily rewards, then N mode cards. A "group gap"
        // separates the first three; a tighter "mode gap" separates the cards.
        final sampleCount = children(1.0).length;
        final modeGapCount = sampleCount - 3;

        // Height at scale 1.0: sections + the gaps between them.
        final base = children(1.0).fold<double>(0, (sum, s) => sum + s.height) + 2 * _groupGap + modeGapCount * _modeGap;
        final scale = (constraints.maxHeight / base).clamp(_minScale, _maxScale);
        final sections = children(scale);

        final used = sections.fold<double>(0, (sum, s) => sum + s.height) + 2 * _groupGap * scale + modeGapCount * _modeGap;
        final spare = constraints.maxHeight - used;
        final scrolls = spare < 0;
        // Leftover space goes above the name, between the groups and below the modes.
        final extra = scrolls ? 0.0 : spare / 4;
        final groupGap = _groupGap * scale + extra;

        final column = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: extra),
            for (var i = 0; i < sections.length; i++) ...[
              if (i > 0) SizedBox(height: i <= 2 ? groupGap : _modeGap),
              sections[i].child.sized(sections[i].height),
            ],
            SizedBox(height: extra),
          ],
        );
        return scrolls ? SingleChildScrollView(child: column) : column;
      },
    );
  }
}

extension on Widget {
  Widget sized(double height) => SizedBox(height: height, child: this);
}

class _ModeCard extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final Color color;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double scale;

  const _ModeCard({
    this.icon,
    this.imageAsset,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final iconSize = 56.0 * scale;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: GlassCard(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10 * scale),
          radius: 24,
          child: Row(
            children: [
              if (imageAsset != null)
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Image.asset(imageAsset!, fit: BoxFit.contain),
                )
              else
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color.lerp(color, Colors.white, 0.25)!, color],
                    ),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: Icon(icon, color: GameColors.night0, size: 28),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GameText(title, size: 20 * scale, textAlign: TextAlign.left, shadow: null),
                    const SizedBox(height: 3),
                    GameText(subtitle, size: 13 * scale, color: GameColors.textDim, textAlign: TextAlign.left, shadow: null, weight: 500),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!, const SizedBox(width: 6)],
              if (enabled) const Icon(Icons.chevron_right_rounded, color: GameColors.textDim, size: 26),
            ],
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
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: GameColors.pill,
        borderRadius: BorderRadius.circular(24),
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
                    Icon(item.icon, color: Colors.white, size: 24),
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
