import 'package:flutter/material.dart';
import '../../../core/constants.dart'; // Note the extra ../ to reach core

class AppLogo extends StatelessWidget {
  final double size;

  // Use 'const' here for the constructor
  const AppLogo({super.key, this.size = 120.0});

  @override
  Widget build(BuildContext context) {
    // DO NOT use 'const' before Image.asset
    return Image.asset(
      AppAssets.logo,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}