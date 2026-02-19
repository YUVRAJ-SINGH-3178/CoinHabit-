import 'package:flutter/material.dart';
import 'package:version/core/constants/app_colors.dart';

class BrandWordmark extends StatelessWidget {
  final double iconSize;
  final double fontSize;

  const BrandWordmark({
    super.key,
    this.iconSize = 26,
    this.fontSize = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(iconSize),
            border: Border.all(color: AppColors.primaryGoldDark, width: 2),
          ),
          child: Icon(
            Icons.savings_outlined,
            color: AppColors.primaryGoldDark,
            size: iconSize * 0.62,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'CoinHabit',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryGoldDark,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }
}
