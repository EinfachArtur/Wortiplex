import 'package:flutter/material.dart';

import '../../core/theme/game_style.dart';
import '../screens/shop/shop_screen.dart';
import 'game_pills.dart';

/// Common frame of every screen: night-sky background, a header row with an
/// optional back button, title and coin balance, and the screen body.
class GameScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBack;
  final bool showCoins;
  final VoidCallback? onCoinsTap;
  final List<Widget> actions;
  final Widget body;
  final Widget? bottom;

  const GameScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack = true,
    this.showCoins = true,
    this.onCoinsTap,
    this.actions = const [],
    required this.body,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.night0,
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(showBack ? 0 : 16, 8, 16, 8),
                child: Row(
                  children: [
                    if (showBack) const GameBackButton(),
                    if (showBack) const SizedBox(width: 12),
                    Expanded(
                      child: titleWidget ??
                          (title == null ? const SizedBox.shrink() : GameText(title!, size: 24, textAlign: TextAlign.left)),
                    ),
                    for (final a in actions) ...[a, const SizedBox(width: 8)],
                    if (showCoins)
                      CoinPill(
                        onAdd: onCoinsTap ?? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopScreen())),
                      ),
                  ],
                ),
              ),
              Expanded(child: body),
              ?bottom,
            ],
          ),
        ),
      ),
    );
  }
}
