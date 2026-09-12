import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MeloLogoWidget extends StatelessWidget {
  final double size;
  final bool showText;
  final double fontSize;

  const MeloLogoWidget({
    super.key,
    this.size = 42,
    this.showText = true,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primaryGold, AppColors.primaryAmber],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGold.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: Image.asset(
              'assets/images/melo-logo.png',
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => const Icon(
                Icons.piano,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, AppColors.primaryGold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              'Melo',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: AppColors.primaryGold,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
