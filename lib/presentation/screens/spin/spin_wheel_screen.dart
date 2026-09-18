import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/economy_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/game_style.dart';
import '../../../domain/economy/spin_wheel.dart';
import '../../state/profile_providers.dart';
import '../../widgets/coin_icon.dart';
import '../../widgets/game_pills.dart';
import '../../widgets/sunburst.dart';
import '../shop/shop_screen.dart';
import 'wheel_painter.dart';

class SpinWheelScreen extends ConsumerStatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  ConsumerState<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends ConsumerState<SpinWheelScreen>
    with TickerProviderStateMixin {
  static const _wheel = SpinWheel();
  static const _spinDuration = Duration(milliseconds: 5200);

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: _spinDuration,
  );
  late final AnimationController _lights = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  double _rotation = 0;
  double _from = 0;
  double _to = 0;
  int _lastTick = 0;
  bool _busy = false;
  SpinResult? _won;

  @override
  void initState() {
    super.initState();
    _spin.addListener(_onTick);
  }

  @override
  void dispose() {
    _spin.dispose();
    _lights.dispose();
    super.dispose();
  }

  double get _wedgeAngle => 2 * math.pi / _wheel.wedges.length;

  void _onTick() {
    final t = Curves.easeOutQuart.transform(_spin.value);
    setState(() => _rotation = _from + (_to - _from) * t);
    // A light click every time a wedge passes the pointer.
    final tick = ((-_rotation) / _wedgeAngle).floor();
    if (tick != _lastTick) {
      _lastTick = tick;
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _startSpin() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);

    final notifier = ref.read(profileControllerProvider.notifier);
    final result = await notifier.beginSpin();
    if (result == null) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.notEnoughCoins)));
      }
      return;
    }

    // Land somewhere inside the chosen wedge, after several full turns.
    final jitter = (math.Random().nextDouble() - 0.5) * _wedgeAngle * 0.7;
    final target = -((result.index + 0.5) * _wedgeAngle + jitter);
    final turnsAhead = (_rotation - target) / (2 * math.pi);
    _from = _rotation;
    _to = target + (turnsAhead.ceil() + 5) * 2 * math.pi;
    _lastTick = ((-_rotation) / _wedgeAngle).floor();

    await _spin.forward(from: 0);
    HapticFeedback.mediumImpact();
    await notifier.grantSpinPrize(result.prize);
    if (mounted) setState(() => _won = result);
  }

  void _claim() => setState(() {
    _won = null;
    _busy = false;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileControllerProvider).valueOrNull;
    final freeSpins = ref
        .read(profileControllerProvider.notifier)
        .freeSpinsAvailable();

    return Scaffold(
      backgroundColor: GameColors.background,
      body: GameBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                    child: Row(
                      children: [
                        const GameBackButton(),
                        const Spacer(),
                        CountPill(
                          count: freeSpins,
                          icon: Icons.casino_rounded,
                          iconColor: const Color(0xFFFFD54F),
                        ),
                        const SizedBox(width: 10),
                        CoinPill(
                          onAdd: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ShopScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  _buildWheel(),
                  const Spacer(flex: 2),
                  _buildSpinButton(l10n, freeSpins),
                  const SizedBox(height: 16),
                  _buildStock(
                    profile?.hintTokens ?? 0,
                    profile?.strikeoutTokens ?? 0,
                    profile?.skipsAvailable ?? 0,
                  ),
                  const Spacer(),
                ],
              ),
            ),
            if (_won != null) _buildWinOverlay(l10n, _won!),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth - 24, 420.0);
        return SizedBox(
          width: size,
          height: size + 34,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 30,
                child: AnimatedBuilder(
                  animation: _lights,
                  builder: (_, _) => CustomPaint(
                    size: Size.square(size),
                    painter: WheelPainter(
                      wedges: _wheel.wedges,
                      rotation: _rotation,
                      pulse: _lights.value,
                    ),
                  ),
                ),
              ),
              const Icon(
                Icons.location_on_rounded,
                size: 66,
                color: Color(0xFFE5202A),
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpinButton(AppLocalizations l10n, int freeSpins) {
    final hasFree = freeSpins > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ChunkyButton(
          width: 300,
          height: 96,
          onPressed: _busy ? null : _startSpin,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedText(
                l10n.spinButton,
                size: 38,
                outline: const Color(0xFF2E7A10),
              ),
              if (hasFree)
                OutlinedText(
                  l10n.free,
                  size: 38,
                  outline: const Color(0xFF2E7A10),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CoinIcon(size: 34),
                    const SizedBox(width: 8),
                    OutlinedText(
                      '${EconomyConfig.spinCost}',
                      size: 38,
                      outline: const Color(0xFF2E7A10),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (hasFree)
          Positioned(
            left: -8,
            top: -8,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE5202A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                '$freeSpins',
                style: const TextStyle(
                  fontFamily: kGameFont,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStock(int hints, int strikeouts, int skips) {
    Widget chip(IconData icon, Color color, int n) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: GameColors.pill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Text(
            '$n',
            style: const TextStyle(
              fontFamily: kGameFont,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        chip(Icons.search_rounded, prizeColor(PrizeKind.hint), hints),
        const SizedBox(width: 10),
        chip(
          Icons.gps_fixed_rounded,
          prizeColor(PrizeKind.strikeout),
          strikeouts,
        ),
        const SizedBox(width: 10),
        chip(Icons.skip_next_rounded, prizeColor(PrizeKind.skip), skips),
      ],
    );
  }

  String _prizeName(AppLocalizations l10n, PrizeKind kind) => switch (kind) {
    PrizeKind.coins => l10n.coins,
    PrizeKind.hint => l10n.prizeHint,
    PrizeKind.strikeout => l10n.prizeStrikeout,
    PrizeKind.skip => l10n.prizeSkip,
    PrizeKind.spin => l10n.prizeSpin,
  };

  Widget _buildWinOverlay(AppLocalizations l10n, SpinResult result) {
    final prize = result.prize;
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        builder: (context, t, child) => Container(
          color: Colors.black.withValues(alpha: 0.82 * t.clamp(0.0, 1.0)),
          child: Transform.scale(
            scale: 0.6 + 0.4 * t,
            child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Sunburst(size: 640),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (prize.kind == PrizeKind.coins)
                  const CoinIcon(size: 150)
                else
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: prizeColor(prize.kind),
                      border: Border.all(color: Colors.white, width: 6),
                      boxShadow: [
                        BoxShadow(
                          color: prizeColor(prize.kind).withValues(alpha: 0.7),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                    child: Icon(
                      prizeIcon(prize.kind),
                      color: Colors.white,
                      size: 92,
                    ),
                  ),
                const SizedBox(height: 14),
                OutlinedText(
                  '+${prize.amount}',
                  size: 64,
                  color: const Color(0xFFFFE04A),
                  outline: const Color(0xFF3B2A00),
                ),
                OutlinedText(_prizeName(l10n, prize.kind), size: 26),
                const SizedBox(height: 40),
                ChunkyButton(
                  width: 230,
                  height: 72,
                  onPressed: _claim,
                  child: OutlinedText(
                    l10n.claim,
                    size: 34,
                    outline: const Color(0xFF2E7A10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
