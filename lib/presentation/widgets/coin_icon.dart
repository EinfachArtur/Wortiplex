import 'package:flutter/material.dart';

/// WortiPlex coin icon displaying the custom coin asset.
class CoinIcon extends StatelessWidget {
  final double size;
  const CoinIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/coin.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
