import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  static const double fixedSize = 88;
  static const String assetPath = 'assets/images/logo.png';
  static const Color backgroundColor = Color(0xFF222936);

  final double size;
  final double padding;
  final BorderRadius borderRadius;

  const AppLogo({
    super.key,
    this.size = fixedSize,
    this.padding = 14,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      alignment: Alignment.center,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
      ),
    );
  }
}
