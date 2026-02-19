import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:version/core/constants/colors.dart';
import 'package:version/core/widgets/brand_wordmark.dart';
import 'package:version/services/storage_service.dart';
import 'package:version/services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showContent = true;

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  void _startAnimationSequence() {
    Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _showContent = false;
        });
      }
    });

    Timer(const Duration(milliseconds: 2150), () {
      if (!mounted) {
        return;
      }

      final hasCompletedOnboarding =
          StorageService.instance.isOnboardingComplete();
      final hasSession = supabase.auth.currentSession != null;

      if (!hasCompletedOnboarding) {
        context.go('/onboarding');
      } else if (hasSession) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Center(
        child: AnimatedSlide(
          offset: _showContent ? Offset.zero : const Offset(0, -1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 136,
                height: 136,
                child: Lottie.asset('assets/animations/coin_spin.json'),
              ).animate().fadeIn(duration: 420.ms).scale(
                    delay: 120.ms,
                    duration: 500.ms,
                    begin: const Offset(0.88, 0.88),
                    end: const Offset(1, 1),
                  ),
              const SizedBox(height: 16),
              const BrandWordmark(iconSize: 24, fontSize: 34)
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 350.ms),
            ],
          ),
        ),
      ),
    );
  }
}
