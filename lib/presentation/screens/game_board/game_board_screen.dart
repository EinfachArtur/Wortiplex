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
import '../../widgets/game_result_dialog.dart';
import '../../widgets/tile_grid.dart';
import '../../widgets/virtual_keyboard.dart';
import '../shop/shop_screen.dart';

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
    final l10n = AppLocalizations.of(context);
    final roundAsync = ref.watch(roundControllerProvider(_params));
    final streak = ref.watch(profileControllerProvider.select(
      (p) => p.valueOrNull?.statsFor(widget.mode.name, _params.language).currentStreak ?? 0,
    ));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.score.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
            Text('$streak', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          ],
        ),
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
      body: SafeArea(
        child: roundAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (round) => _buildBoard(context, round, l10n),
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context, Round round, AppLocalizations l10n) {
    final keyboardStates = _controller.keyboardStates();
    final skipsAvailable = ref.watch(
      profileControllerProvider.select((p) => p.valueOrNull?.skipsAvailable ?? 0),
    );

    return Column(
      children: [
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: TileGrid(round: round, currentInput: _currentInput),
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
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              _BoosterButton(
                icon: Icons.search,
                cost: EconomyConfig.hintCost,
                color: Colors.orange,
                tooltip: l10n.hint,
                onTap: round.isFinished ? null : _buyHint,
              ),
              const SizedBox(width: 8),
              _BoosterButton(
                icon: Icons.gps_fixed,
                cost: EconomyConfig.letterStrikeoutCost,
                color: Colors.purple,
                tooltip: l10n.strikeOutLetter,
                onTap: round.isFinished ? null : _buyStrikeout,
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildSubmitButton(round, l10n)),
              const SizedBox(width: 8),
              Tooltip(
                message: l10n.skip,
                child: Badge(
                  label: Text('$skipsAvailable'),
                  child: FilledButton.tonal(
                    onPressed: skipsAvailable > 0 && widget.mode != GameMode.daily ? _skipRound : null,
                    child: const Icon(Icons.skip_next),
                  ),
                ),
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
    final String label;
    if (!complete) {
      color = Colors.grey;
      label = l10n.submit;
    } else if (valid) {
      color = Colors.blue;
      label = l10n.submit;
    } else {
      color = Colors.red;
      label = l10n.notAWord;
    }

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      onPressed: round.isFinished ? null : () => _onSubmit(round),
      child: Text(
        label.toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
  }
}

class _BoosterButton extends StatelessWidget {
  final IconData icon;
  final int cost;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _BoosterButton({
    required this.icon,
    required this.cost,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: onTap == null ? Colors.grey : color,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              Text('$cost', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
