import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/economy_config.dart';
import '../../../core/config/word_fever_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/game/game_session.dart';
import '../../../domain/game/word_fever_run.dart';
import '../../../domain/models/game_mode.dart';
import '../../../domain/models/round.dart';
import '../../state/ads_providers.dart';
import '../../state/game_providers.dart';
import '../../state/profile_providers.dart';
import '../../../core/theme/game_style.dart';
import '../../widgets/coin_icon.dart';
import '../../widgets/continue_offer_dialog.dart';
import '../../widgets/game_pills.dart';
import '../../widgets/game_scaffold.dart';
import '../../widgets/game_result_dialog.dart';
import '../../widgets/remove_ads_prompt_dialog.dart';
import '../../widgets/tile_grid.dart';
import '../../widgets/virtual_keyboard.dart';
import '../../widgets/word_fever_result_dialog.dart';

class GameBoardScreen extends ConsumerStatefulWidget {
  final GameMode mode;

  /// The calendar day of the daily puzzle to play (today if null).
  final DateTime? dailyDate;
  const GameBoardScreen({super.key, required this.mode, this.dailyDate});

  @override
  ConsumerState<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends ConsumerState<GameBoardScreen> with WidgetsBindingObserver {
  List<String> _currentLetters = [];
  int _cursorIndex = 0;
  String get _currentInput => _currentLetters.join('');
  final FocusNode _focusNode = FocusNode();
  int _shakeCount = 0;
  BannerAd? _bannerAd;

  // Word Fever: a countdown run made of consecutive words.
  WordFeverRun _run = WordFeverRun.start();
  Timer? _clock;
  bool _appActive = true;
  bool _clockPaused = false; // while a finished word plays its reveal animation
  bool _runOver = false;
  int _bonusFlash = 0; // seconds just gained, shown briefly next to the clock

  bool get _isFever => widget.mode == GameMode.wordFever;

  @override
  void initState() {
    super.initState();
    if (_isFever) WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeLoadBanner();
      if (_isFever) {
        _startRun();
        return;
      }
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
  }

  Future<void> _startRun() async {
    _clock?.cancel();
    await ref.read(roundControllerProvider(_params).future); // word list loaded
    if (!mounted) return;
    await _controller.newRound(_params);
    if (!mounted) return;
    final len = ref.read(roundControllerProvider(_params)).valueOrNull?.solutionWord.length ?? 5;
    setState(() {
      _run = WordFeverRun.start();
      _runOver = false;
      _clockPaused = false;
      _bonusFlash = 0;
      _currentLetters = List.filled(len, '');
      _cursorIndex = 0;
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _onClockTick());
  }

  void _onClockTick() {
    if (!mounted || !_appActive || _clockPaused || _runOver) return;
    setState(() => _run = _run.tick());
    if (_run.isOver) unawaited(_endRun());
  }

  Future<void> _endRun() async {
    if (_runOver) return;
    _runOver = true;
    _clock?.cancel();
    final payout = await ref
        .read(profileControllerProvider.notifier)
        .recordWordFeverRun(score: _run.score, solved: _run.solved);
    ref.read(adsServiceProvider).onRoundCompleted();
    if (!mounted) return;
    final best = ref.read(profileControllerProvider).valueOrNull?.wordFeverBest ?? _run.score;
    await WordFeverResultDialog.show(
      context,
      run: _run,
      payout: payout,
      best: best,
      onPlayAgain: _startRun,
      onHome: () => Navigator.of(context).pop(),
    );
  }

  /// A word ended (solved or out of attempts): score it, let the reveal play
  /// with the clock paused, then deal the next word.
  Future<void> _onFeverWordFinished(Round round) async {
    final l10n = AppLocalizations.of(context);
    final won = round.result == RoundResult.won;
    _clockPaused = true;
    setState(() {
      if (won) {
        _run = _run.withSolved(attemptsLeft: round.attemptsLeft);
        _bonusFlash = WordFeverConfig.solveBonusSeconds;
      } else {
        _run = _run.withFailed();
      }
    });
    if (won) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _bonusFlash = 0);
      });
    } else {
      _showSnack(l10n.solutionWas(round.solutionWord));
    }
    await Future.delayed(
      TileGrid.revealDuration(round.solutionWord.length) + (won ? TileGrid.winWaveDuration : const Duration(milliseconds: 1400)),
    );
    if (!mounted || _runOver) return;
    await _controller.newRound(_params);
    final len = ref.read(roundControllerProvider(_params)).valueOrNull?.solutionWord.length ?? 5;
    if (!mounted) return;
    setState(() {
      _currentLetters = List.filled(len, '');
      _cursorIndex = 0;
      _clockPaused = false;
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
    if (round.isFinished || _runOver || _clockPaused) return;
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
    if (_isFever) {
      await _onFeverWordFinished(outcome.round);
      return;
    }

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
    ref.read(adsServiceProvider).onRoundCompleted();
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
    );
  }

  Future<void> _buyHint() async {
    final l10n = AppLocalizations.of(context);
    final result = await _controller.buyHint();
    if (result == null) {
      _showSnack(l10n.notEnoughCoins);
      return;
    }
    final round = ref.read(roundControllerProvider(_params)).valueOrNull;
    final len = round?.solutionWord.length ?? 5;
    _ensureLetterList(len);
    setState(() {
      _currentLetters[result.position] = result.letter;
    });
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
    if (_isFever) setState(() => _run = _run.withFailed());
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
    final isAdFree = ref.watch(profileControllerProvider.select(
      (p) => p.valueOrNull?.subscription.isAdFree ?? false,
    ));
    final l10n = AppLocalizations.of(context);

    return GameScaffold(
      titleWidget: Row(
        children: [
          if (!isAdFree)
            NoAdsButton(
              onTap: () => RemoveAdsPromptDialog.show(),
            )
          else
            const SizedBox(width: 42),
          const Spacer(),
          if (_isFever)
            _ScoreChip(icon: Icons.bolt_rounded, label: l10n.feverScore, value: _run.score)
          else
            _ScoreChip(
              icon: widget.mode == GameMode.daily ? Icons.calendar_month_rounded : Icons.local_fire_department_rounded,
              label: l10n.score,
              value: streak,
            ),
          const Spacer(),
        ],
      ),
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
                      if (_isFever)
                        _FeverClock(secondsLeft: _run.secondsLeft, bonus: _bonusFlash, combo: _run.combo)
                      else
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
            guessCount: round.guesses.length,
            onLetter: (l) => _onLetter(l, round),
            onBackspace: _onBackspace,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                _ToolButton(
                  imageAsset: 'assets/images/glühbirne_1.png',
                  color: GameColors.amber,
                  tooltip: l10n.hint,
                  cost: EconomyConfig.hintCost,
                  tokens: profile?.hintTokens ?? 0,
                  onTap: round.isFinished ? null : _buyHint,
                ),
                const SizedBox(width: 8),
                _ToolButton(
                  imageAsset: 'assets/images/fadenkreuz_1.png',
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
                  imageAsset: 'assets/images/Skip_1.png',
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

/// Countdown bar of a Word Fever run; turns red when time is nearly up.
class _FeverClock extends StatelessWidget {
  final int secondsLeft;
  final int bonus;
  final int combo;
  const _FeverClock({required this.secondsLeft, required this.bonus, required this.combo});

  @override
  Widget build(BuildContext context) {
    final low = secondsLeft <= WordFeverConfig.lowTimeSeconds;
    final color = low ? GameColors.coral : (secondsLeft <= 30 ? GameColors.amber : GameColors.mint);
    final progress = (secondsLeft / WordFeverConfig.startSeconds).clamp(0.0, 1.0);
    final minutes = secondsLeft ~/ 60;
    final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
    return Container(
      key: const ValueKey('fever_clock'),
      width: 300,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: GameColors.glass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1.6),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_rounded, color: color, size: 24),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            child: GameText('$minutes:$seconds', size: 22, color: color, shadow: null, textAlign: TextAlign.left),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: color,
                backgroundColor: GameColors.pill,
              ),
            ),
          ),
          SizedBox(
            width: 54,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: bonus > 0 ? 1 : 0,
              child: GameText('+${bonus}s', size: 16, color: GameColors.mint, shadow: null, textAlign: TextAlign.right),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  const _ScoreChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, color: GameColors.amber, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GameText(label.toUpperCase(), size: 10, color: GameColors.textDim, shadow: null, weight: 600),
              GameText('$value', size: 20, shadow: null),
            ],
          ),
        ],
      ),
    );
  }
}

/// Square glass button for a booster (with cost or stock) or the skip action.
class _ToolButton extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final Color color;
  final String tooltip;
  final int? cost;
  final int tokens;
  final String? badge;
  final VoidCallback? onTap;

  const _ToolButton({
    this.icon,
    this.imageAsset,
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
                  child: Center(
                    child: imageAsset != null
                        ? Opacity(
                            opacity: enabled ? 1.0 : 0.4,
                            child: Image.asset(
                              imageAsset!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Icon(icon, color: enabled ? color : color.withValues(alpha: 0.35), size: 28),
                  ),
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
