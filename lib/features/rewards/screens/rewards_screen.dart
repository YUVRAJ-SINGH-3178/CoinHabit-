import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:version/features/rewards/providers/badge_providers.dart';
import 'package:version/features/rewards/widgets/badge_grid_item.dart';
import 'package:version/features/rewards/widgets/level_card.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBadges = ref.watch(allBadgesProvider);
    final earnedBadgesAsync = ref.watch(earnedBadgesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards & Badges'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LevelCard()
                .animate()
                .fadeIn(duration: 320.ms)
                .slideY(begin: .1, end: 0),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Earn badges by maintaining streaks, completing goals, and contributing consistently.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'My Badges',
              style: Theme.of(context).textTheme.headlineSmall,
            ).animate().fadeIn(delay: 120.ms, duration: 260.ms),
            const SizedBox(height: 12),
            earnedBadgesAsync.when(
              data: (earnedBadges) {
                final earnedBadgeKeys =
                    earnedBadges.map((b) => b.badgeKey).toSet();
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: allBadges.length,
                  itemBuilder: (context, index) {
                    final badgeInfo = allBadges[index];
                    final isEarned =
                        earnedBadgeKeys.contains(badgeInfo['key']!);
                    return BadgeGridItem(
                            badgeInfo: badgeInfo, isEarned: isEarned)
                        .animate()
                        .fadeIn(delay: (index * 45).ms, duration: 260.ms)
                        .scale(
                            begin: const Offset(.9, .9),
                            end: const Offset(1, 1));
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text('Unable to load badges: $err'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
