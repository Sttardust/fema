import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  final double width;
  final Color? color;
  final bool isWhite;

  const AppLogo({
    super.key,
    this.width = 150,
    this.color,
    this.isWhite = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoPath = isWhite 
        ? 'assets/icons/Ai logo white.svg' 
        : 'assets/icons/Ai logo color.svg';
        
    return SvgPicture.asset(
      logoPath,
      width: width,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      placeholderBuilder: (BuildContext context) => const SizedBox(),
    );
  }
}
