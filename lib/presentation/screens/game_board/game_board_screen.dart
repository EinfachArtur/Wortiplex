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
import '../../widgets/coin_hud.dart';
import '../../widgets/tile_grid.dart';
import '../../widgets/virtual_keyboard.dart';
import '../shop/shop_screen.dart';

class GameBoardScreen extends ConsumerStatefulWidget {
  final GameMode mode;
  const GameBoardScreen({super.key, required this.mode});

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

  GameParams get _params {
    final language = ref.read(profileControllerProvider).valueOrNull?.language;
    return GameParams(mode: widget.mode, language: language ?? ref.read(profileControllerProvider).value!.language);
  }

  void _onLetter(String letter, Round round) {
    if (round.isFinished) return;
    if (_currentInput.length >= round.solutionWord.length) return;
    setState(() => _currentInput += letter);
  }

  void _onBackspace() {
    if (_currentInput.isEmpty) return;
    setState(() => _currentInput = _currentInput.substring(0, _currentInput.length - 1));
  }

  Future<void> _onEnter(Round round) async {
    final l10n = AppLocalizations.of(context);
    if (_currentInput.length != round.solutionWord.length) {
      _showSnack(l10n.notEnoughLetters);
      return;
    }
    final controller = ref.read(roundControllerProvider(_params).notifier);
    final outcome = await controller.submitGuess(_currentInput);
    if (outcome is GuessRejected) {
      if (outcome.reason == GuessRejectReason.notInDictionary) {
        _showSnack(l10n.notInWordList);
      }
      return;
    }
    if (outcome is GuessAccepted) {
      setState(() => _currentInput = '');
      if (outcome.round.isFinished) {
        ref.read(adsServiceProvider).onRoundCompleted();
        _showResultDialog(outcome.round);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 1)));
  }

  void _showResultDialog(Round round) {
    final l10n = AppLocalizations.of(context);
    final won = round.result == RoundResult.won;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(won ? l10n.youWon : l10n.youLost),
        content: Text(l10n.solutionWas(round.solutionWord)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(roundControllerProvider(_params).notifier).newRound(_params);
            },
            child: Text(l10n.newGame),
          ),
        ],
      ),
    );
  }

  Future<void> _buyHint(Round round) async {
    final l10n = AppLocalizations.of(context);
    final result = await ref.read(roundControllerProvider(_params).notifier).buyHint();
    if (result == null) {
      _showSnack(l10n.notEnoughCoins);
      return;
    }
    _showSnack('${result.letter} @ ${result.position + 1}');
  }

  Future<void> _buyStrikeout() async {
    final l10n = AppLocalizations.of(context);
    final letter = await ref.read(roundControllerProvider(_params).notifier).buyLetterStrikeout();
    if (letter == null) {
      _showSnack(l10n.notEnoughCoins);
    }
  }

  Future<void> _skipRound() async {
    final used = await ref.read(profileControllerProvider.notifier).useSkip();
    if (!used) return;
    await ref.read(roundControllerProvider(_params).notifier).newRound(_params);
    setState(() => _currentInput = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roundAsync = ref.watch(roundControllerProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(widget.mode, l10n)),
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
      body: roundAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (round) {
          final controller = ref.read(roundControllerProvider(_params).notifier);
          final keyboardStates = controller.keyboardStates();
          final skipsAvailable = ref.watch(
            profileControllerProvider.select((p) => p.valueOrNull?.skipsAvailable ?? 0),
          );
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TileGrid(round: round, currentInput: _currentInput),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _BoosterButton(
                              icon: Icons.search,
                              cost: EconomyConfig.hintCost,
                              tooltip: l10n.hint,
                              onTap: round.isFinished ? null : () => _buyHint(round),
                            ),
                            const SizedBox(width: 16),
                            _BoosterButton(
                              icon: Icons.gps_fixed,
                              cost: EconomyConfig.letterStrikeoutCost,
                              tooltip: l10n.strikeOutLetter,
                              onTap: round.isFinished ? null : _buyStrikeout,
                            ),
                            const SizedBox(width: 16),
                            Tooltip(
                              message: l10n.skip,
                              child: OutlinedButton.icon(
                                onPressed: skipsAvailable > 0 ? _skipRound : null,
                                icon: const Icon(Icons.fast_forward, size: 18),
                                label: Text('$skipsAvailable'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              VirtualKeyboard(
                language: round.language,
                letterStates: keyboardStates.cast(),
                disabledLetters: round.disabledLetters,
                onLetter: (l) => _onLetter(l, round),
                onEnter: () => _onEnter(round),
                onBackspace: _onBackspace,
              ),
              if (_bannerAd != null)
                SizedBox(
                  height: _bannerAd!.size.height.toDouble(),
                  width: _bannerAd!.size.width.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
            ],
          );
        },
      ),
    );
  }

  String _titleFor(GameMode mode, AppLocalizations l10n) => switch (mode) {
        GameMode.classic => l10n.menuClassic,
        GameMode.daily => l10n.menuDaily,
        GameMode.wordFever => l10n.menuWordFever,
        GameMode.secretWord => l10n.menuSecretWord,
        GameMode.together => l10n.menuTogether,
      };
}

class _BoosterButton extends StatelessWidget {
  final IconData icon;
  final int cost;
  final String tooltip;
  final VoidCallback? onTap;

  const _BoosterButton({required this.icon, required this.cost, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text('$cost'),
      ),
    );
  }
}
