import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../widgets/continue_offer_dialog.dart';
import '../../widgets/game_scaffold.dart';
import '../../widgets/remove_ads_prompt_dialog.dart';
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
  List<String> _currentLetters = [];
  int _cursorIndex = 0;
  String get _currentInput => _currentLetters.join('');
  final FocusNode _focusNode = FocusNode();
  int _shakeCount = 0;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeLoadBanner();
      ref.read(profileControllerProvider.notifier).refreshSkips();
      final currentRound = ref.read(roundControllerProvider(_params)).valueOrNull;
      if (currentRound != null && currentRound.isFinished && widget.mode != GameMode.daily) {
        _controller.newRound(_params);
      }
    });
  }

  void _ensureLetterList(int length) {
    if (_currentLetters.length != length) {
      _currentLetters = List.filled(length, '');
      _cursorIndex = 0;
    }
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
    _focusNode.dispose();
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
    final len = round.solutionWord.length;
    _ensureLetterList(len);
    setState(() {
      _currentLetters[_cursorIndex] = letter;
      if (_cursorIndex < len - 1) {
        _cursorIndex++;
      }
    });
  }

  void _onBackspace() {
    if (_currentLetters.isEmpty) return;
    setState(() {
      if (_currentLetters[_cursorIndex].isNotEmpty) {
        _currentLetters[_cursorIndex] = '';
      } else if (_cursorIndex > 0) {
        _cursorIndex--;
        _currentLetters[_cursorIndex] = '';
      }
    });
  }

  void _onTileTap(int col) {
    setState(() {
      _cursorIndex = col;
    });
  }

  void _handleKeyEvent(KeyEvent event, Round round) {
    if (event is! KeyDownEvent) return;
    if (round.isFinished) return;

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _onBackspace();
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _onSubmit(round);
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        if (_cursorIndex > 0) _cursorIndex--;
      });
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() {
        final len = round.solutionWord.length;
        if (_cursorIndex < len - 1) _cursorIndex++;
      });
      return;
    }

    final char = event.character;
    if (char != null && char.isNotEmpty) {
      final upper = char.toUpperCase();
      final normalized = upper == 'ß' ? 'S' : upper;
      final alphabet = alphabetFor(round.language);
      if (alphabet.contains(normalized)) {
        _onLetter(normalized, round);
      }
    }
  }

  /// Rejects the current input: the active row shakes, the device buzzes, and an error hint is shown.
  void _reject(String message) {
    HapticFeedback.heavyImpact();
    setState(() => _shakeCount++);
    _showSnack(message);
  }

  Future<void> _onSubmit(Round round) async {
    final l10n = AppLocalizations.of(context);
    if (round.isFinished) return;
    final len = round.solutionWord.length;
    _ensureLetterList(len);
    if (_currentLetters.any((l) => l.isEmpty)) {
      _reject(l10n.notEnoughLetters);
      return;
    }
    final word = _currentLetters.join('');
    if (!_controller.isValidWord(word)) {
      _reject(l10n.notInWordList);
      return;
    }
    final outcome = await _controller.submitGuess(word);
    if (outcome is! GuessAccepted) return;
    setState(() {
      _currentLetters = List.filled(len, '');
      _cursorIndex = 0;
    });
    if (!outcome.round.isFinished) return;

    // Let the reveal flip (and the win wave) play out before any dialog covers it.
    final won = outcome.round.result == RoundResult.won;
    await Future.delayed(TileGrid.revealDuration(len) + (won ? TileGrid.winWaveDuration : const Duration(milliseconds: 500)));
    if (!mounted) return;

    if (outcome.round.result == RoundResult.lost && _controller.canOfferExtraAttempt) {
      if (!mounted) return;
      final streak = ref.read(profileControllerProvider).valueOrNull?.statsFor(widget.mode.name, _params.language).currentStreak ?? 0;
      final wantsExtra = await ContinueOfferDialog.show(context, streak: streak);
      if (wantsExtra) {
        // If paying fails (e.g. the balance changed) the loss simply stands.
        if (await _controller.buyExtraAttempt()) return;
      }
    }
    await _finishRound(outcome.round);
  }

  Future<void> _finishRound(Round lostOrWon) async {
    if (lostOrWon.result == RoundResult.lost) await _controller.finalizeLoss();
    if (mounted) _showResultDialog(lostOrWon);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 1)));
  }

  void _showResultDialog(Round round) {
    final won = round.result == RoundResult.won;
    final streak = ref.read(profileControllerProvider).valueOrNull?.statsFor(widget.mode.name, _params.language).currentStreak ?? 0;
    final isDaily = round.mode == GameMode.daily;
    // Capture what the ad needs now: the screen may already be gone when the dialog closes.
    final ads = ref.read(adsServiceProvider);
    final adFree = ref.read(profileControllerProvider).valueOrNull?.subscription.isAdFree ?? false;
    final container = ProviderScope.containerOf(context);
    GameResultDialog.show(
      context,
      round: round,
      streak: streak,
      coinsWon: won ? EconomyConfig.roundCompletionReward : null,
      onNextRound: () {
        if (isDaily) {
          Navigator.of(context).pop(); // the daily puzzle can only be played once
        } else {
          _controller.newRound(_params);
          final len = ref.read(roundControllerProvider(_params)).valueOrNull?.solutionWord.length ?? 5;
          setState(() {
            _currentLetters = List.filled(len, '');
            _cursorIndex = 0;
          });
        }
      },
      onHome: () {
        if (!isDaily) {
          _controller.newRound(_params);
        }
        Navigator.of(context).pop();
      },
    ).then((_) {
      // The round is over and its result has been seen: play the ad clip and,
      // once it is closed, offer the ad-free upgrade.
      if (adFree) return;
      ads.onRoundCompleted(onAdClosed: () {
        final stillShowsAds = !(container.read(profileControllerProvider).valueOrNull?.subscription.isAdFree ?? false);
        if (stillShowsAds && container.read(removeAdsPromptCadenceProvider).onRoundCompleted()) {
          RemoveAdsPromptDialog.show();
        }
      });
    });
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
    final len = ref.read(roundControllerProvider(_params)).valueOrNull?.solutionWord.length ?? 5;
    setState(() {
      _currentLetters = List.filled(len, '');
      _cursorIndex = 0;
    });
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
    _ensureLetterList(round.solutionWord.length);
    final l10n = AppLocalizations.of(context);
    final keyboardStates = _controller.keyboardStates();
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    final skipsAvailable = profile?.skipsAvailable ?? 0;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (e) => _handleKeyEvent(e, round),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 36,
                              height: 36,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const GameText(
                            'WortiPlex',
                            size: 28,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      TileGrid(
                        round: round,
                        currentLetters: _currentLetters,
                        cursorIndex: _cursorIndex,
                        onTileTap: _onTileTap,
                        shakeCount: _shakeCount,
                      ),
                    ],
                  ),
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
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
          if (profile == null || !profile.subscription.isAdFree)
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
    );
  }

  Widget _buildSubmitButton(Round round, AppLocalizations l10n) {
    final complete = _currentLetters.length == round.solutionWord.length && !_currentLetters.any((l) => l.isEmpty);
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
