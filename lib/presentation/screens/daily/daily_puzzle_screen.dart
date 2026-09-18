import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/economy_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/game_style.dart';
import '../../../domain/economy/monthly_prizes.dart';
import '../../../domain/models/game_mode.dart';
import '../../../domain/models/language.dart';
import '../../state/profile_providers.dart';
import '../../widgets/coin_icon.dart';
import '../../widgets/game_pills.dart';
import '../../widgets/hex_badge.dart';
import '../game_board/game_board_screen.dart';
import '../shop/shop_screen.dart';

const _tierColors = [
  [Color(0xFFF2A76B), Color(0xFFB8672D)], // bronze
  [Color(0xFFE9EEF5), Color(0xFF8E9BB0)], // silver
  [Color(0xFFFFE08A), Color(0xFFE59A00)], // gold
];

/// How many months back the player may catch up on missed puzzles.
const _monthsBack = 12;

class DailyPuzzleScreen extends ConsumerStatefulWidget {
  const DailyPuzzleScreen({super.key});

  @override
  ConsumerState<DailyPuzzleScreen> createState() => _DailyPuzzleScreenState();
}

class _DailyPuzzleScreenState extends ConsumerState<DailyPuzzleScreen> {
  int _tab = 0;
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _year = DateTime.now().year;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _canGoNextMonth => _month.isBefore(DateTime(_today.year, _today.month));

  bool get _canGoPrevMonth => _month.isAfter(DateTime(_today.year, _today.month - _monthsBack));

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  void _play(DateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameBoardScreen(mode: GameMode.daily, dailyDate: date)),
    );
  }

  void _onDayTap(DateTime date, Language language) {
    final l10n = AppLocalizations.of(context);
    final history = ref.read(profileControllerProvider).requireValue.dailyHistory;
    if (date.isAfter(_today)) {
      _snack(l10n.puzzleLocked);
    } else if (history.hasPlayed(language, date)) {
      _snack(l10n.dailyAlreadyPlayed);
    } else {
      _play(date);
    }
  }

  Future<void> _onPrizeTap(Language language, int tierIndex, int wins, bool claimed) async {
    final l10n = AppLocalizations.of(context);
    final tier = EconomyConfig.monthlyPrizes.tiers[tierIndex];
    if (claimed) return;
    if (!EconomyConfig.monthlyPrizes.isReached(tierIndex, wins)) {
      _snack('${l10n.winsCount(tier.wins)}  =  +${tier.coins} ${l10n.coins}');
      return;
    }
    final coins = await ref
        .read(profileControllerProvider.notifier)
        .claimMonthlyPrize(language, _month.year, _month.month, tierIndex);
    if (coins != null && mounted) _snack('${l10n.prizeClaimed}  +$coins ${l10n.coins}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: GameColors.night0,
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                child: Row(
                  children: [
                    const GameBackButton(),
                    const Spacer(),
                    CoinPill(
                      onAdd: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildSegments(l10n),
              const SizedBox(height: 14),
              _buildNavigator(context),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: _tab == 0 ? _buildPuzzles(context, profile.language) : _buildTrophies(context, profile.language),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegments(AppLocalizations l10n) {
    Widget segment(int index, String label, IconData icon) {
      final selected = _tab == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 42,
            decoration: BoxDecoration(color: selected ? GameColors.mint : Colors.transparent, borderRadius: BorderRadius.circular(21)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: selected ? GameColors.night0 : GameColors.textDim),
                const SizedBox(width: 8),
                GameText(label, size: 16, color: selected ? GameColors.night0 : GameColors.textDim, shadow: null),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: GameColors.pill,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: GameColors.glassBorder),
      ),
      child: Row(children: [
        segment(0, l10n.tabPuzzles, Icons.grid_view_rounded),
        segment(1, l10n.tabTrophies, Icons.workspace_premium_rounded),
      ]),
    );
  }

  Widget _buildNavigator(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final title = _tab == 0 ? DateFormat.MMMM(locale).format(_month) : '$_year';
    final subtitle = _tab == 0 ? '${_month.year}' : '';
    final canPrev = _tab == 0 ? _canGoPrevMonth : _year > _today.year - 2;
    final canNext = _tab == 0 ? _canGoNextMonth : _year < _today.year;

    Widget arrow(IconData icon, bool enabled, VoidCallback onTap) => SizedBox(
          width: 44,
          height: 44,
          child: enabled
              ? GestureDetector(
                  onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(color: GameColors.glass, shape: BoxShape.circle, border: Border.all(color: GameColors.glassBorder)),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                )
              : null,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          arrow(Icons.chevron_left_rounded, canPrev, () => setState(() {
                if (_tab == 0) {
                  _month = DateTime(_month.year, _month.month - 1);
                } else {
                  _year--;
                }
              })),
          Expanded(
            child: Column(
              children: [
                GameText(title.toUpperCase(), size: 26),
                if (subtitle.isNotEmpty) GameText(subtitle, size: 14, color: GameColors.textDim, shadow: null, weight: 600),
              ],
            ),
          ),
          arrow(Icons.chevron_right_rounded, canNext, () => setState(() {
                if (_tab == 0) {
                  _month = DateTime(_month.year, _month.month + 1);
                } else {
                  _year++;
                }
              })),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- puzzles

  Widget _buildPuzzles(BuildContext context, Language language) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileControllerProvider).requireValue;
    final wins = profile.dailyHistory.winsInMonth(language, _month.year, _month.month);
    final today = _today;
    final todayPlayed = profile.dailyHistory.hasPlayed(language, today);
    final locale = Localizations.localeOf(context).toString();

    return Column(
      children: [
        _buildGoals(language, wins),
        const SizedBox(height: 14),
        _buildCalendar(context, language, locale),
        const SizedBox(height: 22),
        ChunkyButton(
          width: 290,
          height: 64,
          onPressed: todayPlayed ? null : () => _play(today),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(todayPlayed ? Icons.check_rounded : Icons.play_arrow_rounded, color: GameColors.night0, size: 30),
              const SizedBox(width: 8),
              Flexible(
                child: GameText(
                  l10n.playDate(DateFormat.MMMd(locale).format(today).toUpperCase()),
                  size: 20,
                  color: GameColors.night0,
                  shadow: null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoals(Language language, int wins) {
    final l10n = AppLocalizations.of(context);
    final claimedSet = ref.watch(profileControllerProvider).requireValue.claimedMonthlyPrizes;
    final prizes = EconomyConfig.monthlyPrizes;

    Widget goal(int i) {
      final tier = prizes.tiers[i];
      final reached = prizes.isReached(i, wins);
      final claimed = claimedSet.contains(MonthlyPrizes.claimKey(language.code, _month.year, _month.month, i));
      final state = claimed ? BadgeState.claimed : (reached ? BadgeState.claimable : BadgeState.locked);

      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onPrizeTap(language, i, wins, claimed),
          child: Column(
            children: [
              HexBadge(colors: _tierColors[i], state: state, size: 78),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  width: 74,
                  height: 8,
                  child: LinearProgressIndicator(
                    value: prizes.tierProgress(i, wins),
                    backgroundColor: const Color(0x26FFFFFF),
                    valueColor: AlwaysStoppedAnimation(reached ? GameColors.mint : GameColors.amber),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GameText('${wins.clamp(0, tier.wins)}/${tier.wins}', size: 15, shadow: null),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CoinIcon(size: 16),
                  const SizedBox(width: 4),
                  GameText('+${tier.coins}', size: 14, color: GameColors.amberLight, shadow: null, weight: 700),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: GameText(l10n.monthlyPrizes, size: 18, textAlign: TextAlign.left, shadow: null)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: GameColors.pill, borderRadius: BorderRadius.circular(14)),
                child: GameText(l10n.winsCount(wins), size: 14, color: GameColors.mint, shadow: null),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var i = 0; i < prizes.tiers.length; i++) goal(i)]),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, Language language, String locale) {
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex; // 0 = Sunday
    final history = ref.watch(profileControllerProvider).requireValue.dailyHistory;
    final today = _today;

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekdaySun0 = DateTime(_month.year, _month.month, 1).weekday % 7;
    final offset = (firstWeekdaySun0 - firstDay + 7) % 7;
    final rows = ((offset + daysInMonth) / 7).ceil();

    final headers = [
      for (var k = 0; k < 7; k++) DateFormat.E(locale).format(DateTime(2023, 1, 1 + (firstDay + k) % 7)),
    ];

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      child: Column(
        children: [
          Row(
            children: [
              for (final h in headers)
                Expanded(child: Center(child: GameText(h, size: 13, color: GameColors.textDim, shadow: null, weight: 600))),
            ],
          ),
          const SizedBox(height: 8),
          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: Builder(builder: (context) {
                      final day = r * 7 + c - offset + 1;
                      if (day < 1 || day > daysInMonth) return const SizedBox(height: 50);
                      final date = DateTime(_month.year, _month.month, day);
                      return _DayCell(
                        day: day,
                        isToday: date == today,
                        isFuture: date.isAfter(today),
                        result: history.resultFor(language, date),
                        onTap: () => _onDayTap(date, language),
                      );
                    }),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- trophies

  Widget _buildTrophies(BuildContext context, Language language) {
    final history = ref.watch(profileControllerProvider).requireValue.dailyHistory;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = _today;
    final lastMonth = _year == now.year ? now.month : 12;
    final prizes = EconomyConfig.monthlyPrizes;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.08,
      children: [
        for (var m = lastMonth; m >= 1; m--)
          Builder(builder: (context) {
            final wins = history.winsInMonth(language, _year, m);
            return GlassCard(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GameText(DateFormat.MMMM(locale).format(DateTime(_year, m)).toUpperCase(), size: 15, shadow: null),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < prizes.tiers.length; i++)
                        HexBadge(
                          colors: _tierColors[i],
                          state: prizes.isReached(i, wins) ? BadgeState.earned : BadgeState.locked,
                          size: 42,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GameText(l10n.winsCount(wins), size: 12, color: GameColors.textDim, shadow: null, weight: 600),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isFuture;
  final bool? result; // null = not played
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isFuture,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    BoxDecoration? decoration;
    Color textColor = Colors.white;
    IconData? badge;
    Color badgeColor = GameColors.mint;

    if (isFuture) {
      textColor = Colors.white.withValues(alpha: 0.28);
    } else if (result == true) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [GameColors.mint, GameColors.mintDark]),
      );
      textColor = GameColors.night0;
      badge = Icons.check_rounded;
    } else if (result == false) {
      decoration = BoxDecoration(borderRadius: BorderRadius.circular(14), color: GameColors.slate);
      badge = Icons.close_rounded;
      badgeColor = GameColors.coral;
    } else if (isToday) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: GameColors.amber.withValues(alpha: 0.18),
        border: Border.all(color: GameColors.amber, width: 2.5),
        boxShadow: [BoxShadow(color: GameColors.amber.withValues(alpha: 0.45), blurRadius: 12)],
      );
      textColor = GameColors.amber;
    } else {
      decoration = BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: GameColors.coral.withValues(alpha: 0.7), width: 1.5));
      textColor = GameColors.coral;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 50,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: decoration,
                child: GameText('$day', size: 18, color: textColor, shadow: null),
              ),
              if (badge != null)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(color: GameColors.night0, shape: BoxShape.circle, border: Border.all(color: badgeColor, width: 1.5)),
                    child: Icon(badge, size: 11, color: badgeColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
