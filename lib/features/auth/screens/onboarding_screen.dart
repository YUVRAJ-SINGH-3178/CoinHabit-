import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:version/core/widgets/brand_wordmark.dart';
import 'package:version/navigation/route_names.dart';
import 'package:version/services/storage_service.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _completeOnboardingAndGo(
      BuildContext context, String route) async {
    await StorageService.instance.setOnboardingComplete(true);
    if (context.mounted) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: BrandWordmark(iconSize: 28, fontSize: 36),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Welcome',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Build stronger saving habits with goals, streaks, and rewards.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      const _OnboardingPoint(
                        icon: Icons.flag_outlined,
                        text: 'Track goals with clear progress',
                      ),
                      const _OnboardingPoint(
                        icon: Icons.local_fire_department_outlined,
                        text: 'Stay consistent with daily streaks',
                      ),
                      const _OnboardingPoint(
                        icon: Icons.emoji_events_outlined,
                        text: 'Unlock rewards as you improve',
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: () => _completeOnboardingAndGo(
                            context, RouteNames.signup),
                        child: const Text('Create Account'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () =>
                            _completeOnboardingAndGo(context, RouteNames.login),
                        child: const Text('I already have an account'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _OnboardingPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
