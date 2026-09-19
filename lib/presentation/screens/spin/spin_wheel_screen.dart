import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/economy_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/game_style.dart';
import '../../../domain/economy/spin_wheel.dart';
import '../../state/ads_providers.dart';
import '../../state/profile_providers.dart';
import '../../widgets/coin_icon.dart';
import '../../widgets/game_pills.dart';
import '../shop/shop_screen.dart';
import 'wheel_painter.dart';

class SpinWheelScreen extends ConsumerStatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  ConsumerState<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends ConsumerState<SpinWheelScreen> with TickerProviderStateMixin {
  static const _wheel = SpinWheel();
  static const _spinDuration = Duration(milliseconds: 5200);

  late final AnimationController _spin = AnimationController(vsync: this, duration: _spinDuration);
  late final AnimationController _lights =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);

  double _rotation = 0;
  double _from = 0;
  double _to = 0;
  int _lastTick = 0;
  bool _busy = false;
  SpinResult? _won;
  ui.Image? _coinImage;
  ui.Image? _hintImage;
  ui.Image? _strikeoutImage;
  ui.Image? _skipImage;
  ui.Image? _spinImage;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _spin.addListener(_onTick);
    _loadImages();
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

  Future<ui.Image?> _loadImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadImages() async {
    final results = await Future.wait([
      _loadImage('assets/images/coin.png'),
      _loadImage('assets/images/glühbirne_1.png'),
      _loadImage('assets/images/fadenkreuz_1.png'),
      _loadImage('assets/images/Skip_1.png'),
      _loadImage('assets/images/Glücksrad.png'),
    ]);
    if (mounted) {
      setState(() {
        _coinImage = results[0];
        _hintImage = results[1];
        _strikeoutImage = results[2];
        _skipImage = results[3];
        _spinImage = results[4];
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
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
    final freeSpins = ref.read(profileControllerProvider.notifier).freeSpinsAvailable();

    return Scaffold(
      backgroundColor: GameColors.night0,
      body: GameBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 16, 0),
                    child: Row(
                      children: [
                        const GameBackButton(),
                        const Spacer(),
                        CountPill(count: freeSpins, imageAsset: 'assets/images/Glücksrad.png'),
                        const SizedBox(width: 10),
                        CoinPill(
                          onAdd: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopScreen())),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  GameText(l10n.spinWheelTitle, size: 28),
                  const Spacer(flex: 2),
                  _buildWheel(),
                  const Spacer(flex: 2),
                  _buildSpinButton(l10n, freeSpins),
                  const SizedBox(height: 12),
                  _buildStock(profile?.hintTokens ?? 0, profile?.strikeoutTokens ?? 0, profile?.skipsAvailable ?? 0),
                  const Spacer(flex: 3),
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
            ),
            if (_won != null) _buildWinOverlay(l10n, _won!),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel() {
    return LayoutBuilder(builder: (context, constraints) {
      final size = math.min(constraints.maxWidth - 48, 320.0);
      return SizedBox(
        width: size,
        height: size + 34,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 34,
              child: AnimatedBuilder(
                animation: _lights,
                builder: (_, _) => CustomPaint(
                  size: Size.square(size),
                  painter: WheelPainter(
                    wedges: _wheel.wedges,
                    rotation: _rotation,
                    pulse: _lights.value,
                    coinImage: _coinImage,
                    hintImage: _hintImage,
                    strikeoutImage: _strikeoutImage,
                    skipImage: _skipImage,
                    spinImage: _spinImage,
                  ),
                ),
              ),
            ),
            SizedBox(width: 40, height: 54, child: CustomPaint(painter: PointerPainter())),
          ],
        ),
      );
    });
  }

  Widget _buildSpinButton(AppLocalizations l10n, int freeSpins) {
    final hasFree = freeSpins > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ChunkyButton(
          width: 290,
          height: 68,
          onPressed: _busy ? null : _startSpin,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GameText(l10n.spinButton.toUpperCase(), size: 24, color: GameColors.night0, shadow: null),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: GameColors.night0.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: hasFree
                    ? GameText(l10n.free.toUpperCase(), size: 15, color: GameColors.mint, shadow: null, weight: 800)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CoinIcon(size: 20),
                          const SizedBox(width: 6),
                          GameText('${EconomyConfig.spinCost}', size: 16, shadow: null, weight: 800),
                        ],
                      ),
              ),
            ],
          ),
        ),
        if (hasFree)
          Positioned(
            right: -6,
            top: -8,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GameColors.coral,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: GameColors.coral.withValues(alpha: 0.5), blurRadius: 8),
                ],
              ),
              child: GameText('$freeSpins', size: 16, shadow: null, weight: 800),
            ),
          ),
      ],
    );
  }

  Widget _buildStock(int hints, int strikeouts, int skips) {
    Widget chip(String asset, Color color, int n) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: GameColors.glass,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: GameColors.glassBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(asset, width: 22, height: 22, fit: BoxFit.contain),
            const SizedBox(width: 8),
            GameText('$n', size: 18, shadow: null),
          ]),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        chip('assets/images/glühbirne_1.png', prizeColor(PrizeKind.hint), hints),
        const SizedBox(width: 10),
        chip('assets/images/fadenkreuz_1.png', prizeColor(PrizeKind.strikeout), strikeouts),
        const SizedBox(width: 10),
        chip('assets/images/Skip_1.png', prizeColor(PrizeKind.skip), skips),
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
    final color = prizeColor(prize.kind);
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (context, t, child) {
          final f = t.clamp(0.0, 1.0);
          return Container(
            color: const Color(0xFF0B0724).withValues(alpha: 0.78 * f),
            alignment: Alignment.center,
            child: Transform.scale(scale: 0.7 + 0.3 * t, child: Opacity(opacity: f, child: child)),
          );
        },
        child: Container(
          width: 300,
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3B2A8C), Color(0xFF221860)]),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: GameColors.amber, width: 2.5),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 50)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)]),
                    ),
                  ),
                  if (prize.kind == PrizeKind.coins)
                    const CoinIcon(size: 110)
                  else if (prize.kind == PrizeKind.hint)
                    Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 24)],
                      ),
                      child: Image.asset('assets/images/glühbirne_1.png', fit: BoxFit.contain),
                    )
                  else if (prize.kind == PrizeKind.strikeout)
                    Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 24)],
                      ),
                      child: Image.asset('assets/images/fadenkreuz_1.png', fit: BoxFit.contain),
                    )
                  else if (prize.kind == PrizeKind.skip)
                    Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 24)],
                      ),
                      child: Image.asset('assets/images/Skip_1.png', fit: BoxFit.contain),
                    )
                  else if (prize.kind == PrizeKind.spin)
                    Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 24)],
                      ),
                      child: Image.asset('assets/images/Glücksrad.png', fit: BoxFit.contain),
                    )
                  else
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 24)],
                      ),
                      child: Icon(prizeIcon(prize.kind), color: Color.lerp(color, Colors.black, 0.2), size: 68),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              GameText('+${prize.amount}', size: 54, color: GameColors.amber),
              GameText(_prizeName(l10n, prize.kind), size: 20, color: GameColors.textDim, shadow: null),
              const SizedBox(height: 26),
              ChunkyButton(
                width: 220,
                height: 60,
                onPressed: _claim,
                child: GameText(l10n.claim, size: 24, color: GameColors.night0, shadow: null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
