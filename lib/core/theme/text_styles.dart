import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:version/core/constants/app_colors.dart';

class AppTextStyles {
  static final TextStyle display = GoogleFonts.inter(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: -0.8,
  );

  static final TextStyle h1 = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: -0.6,
  );

  static final TextStyle h2 = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    letterSpacing: -0.3,
  );

  static final TextStyle h3 = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static final TextStyle body = GoogleFonts.inter(
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
    height: 1.4,
  );

  static final TextStyle bodyBold = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static final TextStyle caption = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textMid,
    height: 1.35,
  );

  static final TextStyle coinNumber = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryGold,
  );

  static TextStyle get heading1 => h1;
  static TextStyle get heading2 => h2;
  static TextStyle get bodyText => body;
  static TextStyle get lightBodyText => caption;
}
