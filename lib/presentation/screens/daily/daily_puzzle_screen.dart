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
import '../../widgets/game_pills.dart';
import '../game_board/game_board_screen.dart';
import '../shop/shop_screen.dart';

const _tierColors = [
  [Color(0xFFE9A26A), Color(0xFFB8672D)], // bronze
  [Color(0xFFF3F6F8), Color(0xFF9CA8B3)], // silver
  [Color(0xFFFFE27A), Color(0xFFE59A00)], // gold
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

  bool get _canGoPrevMonth {
    final limit = DateTime(_today.year, _today.month - _monthsBack);
    return _month.isAfter(limit);
  }

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
      backgroundColor: GameColors.background,
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
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
              _buildTabs(l10n),
              _buildRibbon(context),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  decoration: const BoxDecoration(
                    color: GameColors.panel,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
                    child: _tab == 0 ? _buildPuzzles(context, profile.language) : _buildTrophies(context, profile.language),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(AppLocalizations l10n) {
    Widget tab(int index, String label) {
      final selected = _tab == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: Container(
            height: 54,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? GameColors.panelLight : GameColors.panel,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: OutlinedText(label.toUpperCase(), size: 27),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [tab(0, l10n.tabPuzzles), tab(1, l10n.tabTrophies)]),
    );
  }

  Widget _buildRibbon(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final title = _tab == 0 ? DateFormat.yMMMM(locale).format(_month) : '$_year';
    final canPrev = _tab == 0 ? _canGoPrevMonth : _year > _today.year - 2;
    final canNext = _tab == 0 ? _canGoNextMonth : _year < _today.year;

    Widget arrow(bool left, bool enabled, VoidCallback onTap) => SizedBox(
          width: 56,
          child: enabled
              ? IconButton(
                  onPressed: onTap,
                  icon: Icon(left ? Icons.arrow_left_rounded : Icons.arrow_right_rounded, color: Colors.white, size: 54),
                )
              : null,
        );

    return Container(
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF9A55), GameColors.orange],
        ),
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8), right: Radius.circular(8)),
        border: const Border(bottom: BorderSide(color: GameColors.orangeDark, width: 5)),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          arrow(true, canPrev, () => setState(() {
                if (_tab == 0) {
                  _month = DateTime(_month.year, _month.month - 1);
                } else {
                  _year--;
                }
              })),
          Expanded(child: Center(child: OutlinedText(title.toUpperCase(), size: 30, outline: const Color(0xFF9A4310)))),
          arrow(false, canNext, () => setState(() {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF808080),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              children: [
                Text(l10n.monthlyPrizes, style: const TextStyle(fontFamily: kGameFont, fontSize: 22, color: Colors.black87)),
                const SizedBox(height: 8),
                _buildPrizes(language, wins),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildCalendar(context, language, locale),
          const SizedBox(height: 18),
          ChunkyButton(
            width: 250,
            height: 66,
            onPressed: todayPlayed ? null : () => _play(today),
            child: OutlinedText(
              l10n.playDate(DateFormat.MMMd(locale).format(today).toUpperCase()),
              size: 27,
              outline: const Color(0xFF2E7A10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizes(Language language, int wins) {
    final l10n = AppLocalizations.of(context);
    final claimedSet = ref.watch(profileControllerProvider).requireValue.claimedMonthlyPrizes;
    final prizes = EconomyConfig.monthlyPrizes;

    return LayoutBuilder(builder: (context, constraints) {
      final barWidth = constraints.maxWidth;
      const knob = 30.0;
      final progress = prizes.progress(wins);

      Widget positioned(int i, Widget child, {double top = 0}) {
        final center = barWidth * prizes.markerPosition(i);
        return Positioned(left: center - 60, top: top, width: 120, child: child);
      }

      return SizedBox(
        height: 190,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < prizes.tiers.length; i++)
              positioned(
                i,
                Center(
                  child: _PrizeMedal(
                    colors: _tierColors[i],
                    reached: prizes.isReached(i, wins),
                    claimed: claimedSet.contains(MonthlyPrizes.claimKey(language.code, _month.year, _month.month, i)),
                    onTap: () => _onPrizeTap(
                      language,
                      i,
                      wins,
                      claimedSet.contains(MonthlyPrizes.claimKey(language.code, _month.year, _month.month, i)),
                    ),
                  ),
                ),
              ),
            // Progress bar.
            Positioned(
              left: 0,
              right: 0,
              top: 112,
              height: 34,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFA88A2E),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFFCDBE86), width: 2),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 112,
              height: 34,
              width: (barWidth * progress).clamp(knob, barWidth),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFD1B23B), borderRadius: BorderRadius.circular(17)),
              ),
            ),
            for (var i = 0; i < prizes.tiers.length; i++)
              positioned(
                i,
                Center(
                  child: Container(
                    width: 12,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8B233),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFE9A0), width: 2),
                    ),
                  ),
                ),
                top: 107,
              ),
            Positioned(
              left: (barWidth * progress - knob / 2).clamp(0.0, barWidth - knob),
              top: 114,
              child: Container(
                width: knob,
                height: knob,
                decoration: BoxDecoration(
                  color: const Color(0xFF6EE04A),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF5A3D14), width: 4),
                ),
                child: Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF5A3D14), shape: BoxShape.circle))),
              ),
            ),
            for (var i = 0; i < prizes.tiers.length; i++)
              positioned(
                i,
                Center(child: OutlinedText(l10n.winsCount(prizes.tiers[i].wins).toUpperCase(), size: 19)),
                top: 156,
              ),
          ],
        ),
      );
    });
  }

  Widget _buildCalendar(BuildContext context, Language language, String locale) {
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex; // 0 = Sunday
    final profile = ref.watch(profileControllerProvider).requireValue;
    final history = profile.dailyHistory;
    final today = _today;

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekdaySun0 = DateTime(_month.year, _month.month, 1).weekday % 7;
    final offset = (firstWeekdaySun0 - firstDay + 7) % 7;
    final rows = ((offset + daysInMonth) / 7).ceil();

    final headers = [
      for (var k = 0; k < 7; k++) DateFormat.E(locale).format(DateTime(2023, 1, 1 + (firstDay + k) % 7)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              for (final h in headers)
                Expanded(
                  child: Center(child: Text(h, style: const TextStyle(fontFamily: kGameFont, fontSize: 17, color: Colors.black87))),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: Builder(builder: (context) {
                      final day = r * 7 + c - offset + 1;
                      if (day < 1 || day > daysInMonth) return const SizedBox(height: 56);
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
    final locale = Localizations.localeOf(context).toString();
    final now = _today;
    final lastMonth = _year == now.year ? now.month : 12;
    final prizes = EconomyConfig.monthlyPrizes;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        for (var m = lastMonth; m >= 1; m--)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: const Color(0xFFC4C4C4), borderRadius: BorderRadius.circular(22)),
            child: Column(
              children: [
                Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: GameColors.purple,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: OutlinedText(DateFormat.yMMMM(locale).format(DateTime(_year, m)).toUpperCase(), size: 24, outline: const Color(0xFF4A0F6E)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Builder(builder: (context) {
                    final wins = history.winsInMonth(language, _year, m);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var i = 0; i < prizes.tiers.length; i++)
                          _TrophySlot(colors: _tierColors[i], earned: prizes.isReached(i, wins)),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
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
    Color? fill;
    Color textColor;
    if (isFuture) {
      textColor = Colors.white.withValues(alpha: 0.35);
    } else if (result == true) {
      fill = const Color(0xFF4CC93A);
      textColor = Colors.white;
    } else if (result == false) {
      fill = const Color(0xFF4A4A4A);
      textColor = Colors.white;
    } else if (isToday) {
      fill = GameColors.blueDay;
      textColor = Colors.white;
    } else {
      textColor = GameColors.missedRed;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Center(
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: isToday && fill != null && result != null ? Border.all(color: GameColors.blueDay, width: 3) : null,
            ),
            child: Text('$day', style: TextStyle(fontFamily: kGameFont, fontSize: 27, color: textColor)),
          ),
        ),
      ),
    );
  }
}

class _PrizeMedal extends StatelessWidget {
  final List<Color> colors;
  final bool reached;
  final bool claimed;
  final VoidCallback onTap;

  const _PrizeMedal({required this.colors, required this.reached, required this.claimed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final claimable = reached && !claimed;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: reached ? 1 : 0.55,
        child: SizedBox(
          width: 104,
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 2,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: claimable ? GameColors.goldLight : Colors.black38,
                        blurRadius: claimable ? 22 : 6,
                        spreadRadius: claimable ? 3 : 0,
                        offset: claimable ? Offset.zero : const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 44),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 44,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A5A2B),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFF5E3A17), width: 3),
                  ),
                  child: Icon(claimed ? Icons.check_rounded : Icons.redeem_rounded, color: claimed ? const Color(0xFF7CF06A) : GameColors.goldLight, size: 26),
                ),
              ),
              if (claimable)
                Positioned(
                  left: -4,
                  top: -4,
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFFE5202A), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Text('!', style: TextStyle(fontFamily: kGameFont, fontSize: 18, color: Colors.white, height: 1)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrophySlot extends StatelessWidget {
  final List<Color> colors;
  final bool earned;
  const _TrophySlot({required this.colors, required this.earned});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: earned ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors) : null,
        color: earned ? null : const Color(0xFFB0B0B0),
        border: earned ? Border.all(color: Colors.white.withValues(alpha: 0.85), width: 4) : null,
        boxShadow: earned ? const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 3))] : null,
      ),
      child: earned ? const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40) : null,
    );
  }
}
