import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/economy_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/game/game_session.dart';
import '../../../domain/models/game_mode.dart';
import '../../../domain/models/round.dart';
import '../../state/ads_providers.dart';
import '../../state/game_providers.dart';
import '../../state/profile_providers.dart';
import '../../../core/theme/game_style.dart';
import '../../widgets/coin_icon.dart';
import '../../widgets/game_scaffold.dart';
import '../../widgets/game_result_dialog.dart';
import '../../widgets/tile_grid.dart';
import '../../widgets/virtual_keyboard.dart';

class GameBoardScreen extends ConsumerStatefulWidget {
  final GameMode mode;

  /// The calendar day of the daily puzzle to play (today if null).
  final DateTime? dailyDate;
  const GameBoardScreen({super.key, required this.mode, this.dailyDate});

  @override
  ConsumerState<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends ConsumerState<GameBoardScreen> {
  String _currentInput = '';
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeLoadBanner();
      ref.read(profileControllerProvider.notifier).refreshSkips();
    });
  }

  void _maybeLoadBanner() {
    final profile = ref.read(profileControllerProvider).valueOrNull;
    if (profile != null && profile.subscription.isAdFree) return;
    final ads = ref.read(adsServiceProvider);
    setState(() {
      _bannerAd = ads.createBannerAd(
        onLoaded: () => setState(() {}),
        onFailed: () => setState(() => _bannerAd = null),
      );
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  GameParams get _params => GameParams(
        mode: widget.mode,
        language: ref.read(profileControllerProvider).requireValue.language,
        date: widget.mode == GameMode.daily ? (widget.dailyDate ?? DateTime.now()) : null,
      );

  RoundController get _controller => ref.read(roundControllerProvider(_params).notifier);

  void _onLetter(String letter, Round round) {
    if (round.isFinished) return;
    if (_currentInput.length >= round.solutionWord.length) return;
    setState(() => _currentInput += letter);
  }

  void _onBackspace() {
    if (_currentInput.isEmpty) return;
    setState(() => _currentInput = _currentInput.substring(0, _currentInput.length - 1));
  }

  Future<void> _onSubmit(Round round) async {
    final l10n = AppLocalizations.of(context);
    if (round.isFinished) return;
    if (_currentInput.length != round.solutionWord.length) {
      _showSnack(l10n.notEnoughLetters);
      return;
    }
    if (!_controller.isValidWord(_currentInput)) {
      _showSnack(l10n.notInWordList);
      return;
    }
    final outcome = await _controller.submitGuess(_currentInput);
    if (outcome is GuessAccepted) {
      setState(() => _currentInput = '');
      if (outcome.round.isFinished) {
        ref.read(adsServiceProvider).onRoundCompleted();
        if (mounted) _showResultDialog(outcome.round);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 1)));
  }

  void _showResultDialog(Round round) {
    final streak = ref.read(profileControllerProvider).valueOrNull?.statsFor(widget.mode.name, _params.language).currentStreak ?? 0;
    final isDaily = round.mode == GameMode.daily;
    GameResultDialog.show(
      context,
      round: round,
      streak: streak,
      onNextRound: () {
        if (isDaily) {
          Navigator.of(context).pop(); // the daily puzzle can only be played once
        } else {
          _controller.newRound(_params);
        }
      },
    );
  }

  Future<void> _buyHint() async {
    final l10n = AppLocalizations.of(context);
    final result = await _controller.buyHint();
    if (result == null) {
      _showSnack(l10n.notEnoughCoins);
      return;
    }
    _showSnack('${result.position + 1}: ${result.letter}');
  }

  Future<void> _buyStrikeout() async {
    final l10n = AppLocalizations.of(context);
    final letter = await _controller.buyLetterStrikeout();
    if (letter == null) _showSnack(l10n.notEnoughCoins);
  }

  Future<void> _skipRound() async {
    final used = await ref.read(profileControllerProvider.notifier).useSkip();
    if (!used) return;
    await _controller.newRound(_params);
    setState(() => _currentInput = '');
  }

  @override
  Widget build(BuildContext context) {
    final roundAsync = ref.watch(roundControllerProvider(_params));
    final streak = ref.watch(profileControllerProvider.select(
      (p) => p.valueOrNull?.statsFor(widget.mode.name, _params.language).currentStreak ?? 0,
    ));

    return GameScaffold(
      titleWidget: Align(alignment: Alignment.centerLeft, child: _ScoreChip(streak: streak, daily: widget.mode == GameMode.daily)),
      body: roundAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (round) => _buildBoard(context, round),
      ),
    );
  }

  Widget _buildBoard(BuildContext context, Round round) {
    final l10n = AppLocalizations.of(context);
    final keyboardStates = _controller.keyboardStates();
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    final skipsAvailable = profile?.skipsAvailable ?? 0;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TileGrid(round: round, currentInput: _currentInput),
              ),
            ),
          ),
        ),
        VirtualKeyboard(
          language: round.language,
          letterStates: keyboardStates.cast(),
          disabledLetters: round.disabledLetters,
          onLetter: (l) => _onLetter(l, round),
          onBackspace: _onBackspace,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            children: [
              _ToolButton(
                icon: Icons.lightbulb_rounded,
                color: GameColors.amber,
                tooltip: l10n.hint,
                cost: EconomyConfig.hintCost,
                tokens: profile?.hintTokens ?? 0,
                onTap: round.isFinished ? null : _buyHint,
              ),
              const SizedBox(width: 8),
              _ToolButton(
                icon: Icons.block_rounded,
                color: const Color(0xFFFF6B8E),
                tooltip: l10n.strikeOutLetter,
                cost: EconomyConfig.letterStrikeoutCost,
                tokens: profile?.strikeoutTokens ?? 0,
                onTap: round.isFinished ? null : _buyStrikeout,
              ),
              const SizedBox(width: 10),
              Expanded(child: _buildSubmitButton(round, l10n)),
              const SizedBox(width: 10),
              _ToolButton(
                icon: Icons.fast_forward_rounded,
                color: GameColors.mint,
                tooltip: l10n.skip,
                badge: '$skipsAvailable',
                onTap: skipsAvailable > 0 && widget.mode != GameMode.daily && !round.isFinished ? _skipRound : null,
              ),
            ],
          ),
        ),
        if (_bannerAd != null)
          SizedBox(
            height: _bannerAd!.size.height.toDouble(),
            width: _bannerAd!.size.width.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
      ],
    );
  }

  Widget _buildSubmitButton(Round round, AppLocalizations l10n) {
    final complete = _currentInput.length == round.solutionWord.length;
    final valid = complete && _controller.isValidWord(_currentInput);

    final Color color;
    final Color base;
    final Color textColor;
    final String label;
    if (!complete) {
      color = const Color(0xFF59607A);
      base = const Color(0xFF3F4256);
      textColor = Colors.white70;
      label = l10n.submit;
    } else if (valid) {
      color = GameColors.mint;
      base = GameColors.mintDark;
      textColor = GameColors.night0;
      label = l10n.submit;
    } else {
      color = GameColors.coral;
      base = const Color(0xFFC24545);
      textColor = Colors.white;
      label = l10n.notAWord;
    }

    return ChunkyButton(
      height: 54,
      color: color,
      baseColor: base,
      onPressed: round.isFinished ? null : () => _onSubmit(round),
      child: GameText(label.toUpperCase(), size: 18, color: textColor, shadow: null),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final int streak;
  final bool daily;
  const _ScoreChip({required this.streak, required this.daily});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 16, 6),
      decoration: BoxDecoration(
        color: GameColors.glass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GameColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(daily ? Icons.calendar_month_rounded : Icons.local_fire_department_rounded, color: GameColors.amber, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GameText(l10n.score.toUpperCase(), size: 10, color: GameColors.textDim, shadow: null, weight: 600),
              GameText('$streak', size: 20, shadow: null),
            ],
          ),
        ],
      ),
    );
  }
}

/// Square glass button for a booster (with cost or stock) or the skip action.
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final int? cost;
  final int tokens;
  final String? badge;
  final VoidCallback? onTap;

  const _ToolButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
    this.cost,
    this.tokens = 0,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 58,
          height: 66,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: enabled ? 0.22 : 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: enabled ? 0.85 : 0.25), width: 2),
                  ),
                  child: Icon(icon, color: enabled ? color : color.withValues(alpha: 0.35), size: 28),
                ),
              ),
              if (cost != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: GameColors.night0,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GameColors.glassBorder),
                      ),
                      child: tokens > 0
                          ? GameText('×$tokens', size: 12, color: GameColors.mint, shadow: null)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CoinIcon(size: 13),
                                const SizedBox(width: 3),
                                GameText('$cost', size: 12, shadow: null),
                              ],
                            ),
                    ),
                  ),
                ),
              if (badge != null)
                Positioned(
                  right: -4,
                  top: -6,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: GameColors.amber, shape: BoxShape.circle, border: Border.all(color: GameColors.night0, width: 2)),
                    child: GameText(badge!, size: 12, color: GameColors.night0, shadow: null),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
