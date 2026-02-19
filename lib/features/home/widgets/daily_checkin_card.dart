import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:version/features/auth/providers/user_providers.dart';
import 'package:version/core/constants/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:version/features/rewards/providers/badge_providers.dart';
import 'package:version/services/offline_queue_service.dart';
import 'package:version/services/offline_service.dart';
import 'package:version/services/supabase_service.dart';

class DailyCheckinCard extends ConsumerStatefulWidget {
  final VoidCallback onCheckinSuccess;
  const DailyCheckinCard({super.key, required this.onCheckinSuccess});

  @override
  ConsumerState<DailyCheckinCard> createState() => _DailyCheckinCardState();
}

class _DailyCheckinCardState extends ConsumerState<DailyCheckinCard> {
  bool _isCoinAnimationVisible = false;
  bool _isSubmitting = false;

  void _handleCheckin() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (!OfflineService.instance.isOnline) {
        await OfflineQueueService.instance.enqueueCheckIn();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'You are offline. Check-in queued and will sync automatically.'),
            ),
          );
        }
        return;
      }

      final didCheckIn =
          await ref.read(userRepositoryProvider).processCheckIn();

      ref.invalidate(userProfileProvider);

      if (!mounted) {
        return;
      }

      if (didCheckIn) {
        final userId = supabase.auth.currentUser?.id;
        if (userId != null) {
          try {
            await ref.read(badgeRepositoryProvider).syncBadges(userId);
            ref.invalidate(earnedBadgesProvider);
          } catch (_) {}
        }

        widget.onCheckinSuccess();
        setState(() => _isCoinAnimationVisible = true);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _isCoinAnimationVisible = false);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have already checked in today.')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      data: (userProfile) {
        final today = DateTime.now();
        final lastCheckin = userProfile.lastCheckinDate;
        final alreadyCheckedIn = lastCheckin != null &&
            lastCheckin.year == today.year &&
            lastCheckin.month == today.month &&
            lastCheckin.day == today.day;

        return Stack(
          alignment: Alignment.center,
          children: [
            Card(
              color: alreadyCheckedIn
                  ? AppColors.successGreen.withValues(alpha: 0.2)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_fire_department,
                                color: AppColors.primaryGold, size: 32)
                            .animate(target: alreadyCheckedIn ? 1 : 0)
                            .shake(hz: 4, duration: 300.ms)
                            .scale(end: const Offset(1.2, 1.2))
                            .then()
                            .scale(end: const Offset(1.0, 1.0)),
                        const SizedBox(width: 8),
                        Text(
                          'Day ${userProfile.streakCurrent} Streak!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    alreadyCheckedIn
                        ? const Text(
                            'You\'ve checked in today. Come back tomorrow!')
                        : ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleCheckin,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('CHECK IN TODAY'),
                          ),
                  ],
                ),
              ),
            ),
            // Coin animation text
            if (_isCoinAnimationVisible)
              const Text('+10 Coins',
                      style: TextStyle(
                          fontSize: 24,
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.bold))
                  .animate()
                  .move(
                      begin: const Offset(0, 0),
                      end: const Offset(0, -100),
                      duration: 1000.ms,
                      curve: Curves.easeOut)
                  .fadeOut(delay: 500.ms, duration: 500.ms),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
