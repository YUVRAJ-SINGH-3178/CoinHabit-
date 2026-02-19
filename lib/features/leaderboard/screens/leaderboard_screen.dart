import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:version/core/constants/colors.dart';
import 'package:version/core/widgets/shimmer_loading.dart';
import 'package:version/features/leaderboard/providers/leaderboard_providers.dart';
import 'package:version/features/leaderboard/widgets/podium_widget.dart';
import 'package:version/models/leaderboard_entry.dart';
import 'package:version/services/supabase_service.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(weeklyLeaderboardProvider);
    final currentUserId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Leaderboard'),
      ),
      body: leaderboardAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Leaderboard is still calculating. Check back soon!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }

          final topThree = entries.length > 3 ? entries.sublist(0, 3) : entries;
          final everyoneElse =
              entries.length > 3 ? entries.sublist(3) : <LeaderboardEntry>[];

          return Column(
            children: [
              const SizedBox(height: 8),
              PodiumWidget(topThree: topThree)
                  .animate()
                  .fadeIn(duration: 500.ms),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                  itemCount: everyoneElse.length,
                  itemBuilder: (context, index) {
                    final entry = everyoneElse[index];
                    final isCurrentUser = entry.userId == currentUserId;
                    return Card(
                      color: isCurrentUser
                          ? AppColors.primaryGold.withValues(alpha: 0.08)
                          : null,
                      child: ListTile(
                        leading: Text(
                          '#${entry.rank ?? index + 4}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        title: Text(entry.username ?? 'Anonymous'),
                        trailing: Text(
                          entry.coinsThisWeek.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ).animate().slide(
                        delay: (100 * index).ms,
                        duration: 400.ms,
                        begin: const Offset(1, 0));
                  },
                ),
              ),
            ],
          );
        },
        loading: () => _buildLeaderboardShimmer(),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Unable to load leaderboard: $err'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardShimmer() {
    return Column(
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ShimmerLoading.rectangular(width: 80, height: 120),
            ShimmerLoading.rectangular(width: 80, height: 160),
            ShimmerLoading.rectangular(width: 80, height: 100),
          ],
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: 8,
            itemBuilder: (context, index) => const ListTile(
              leading: ShimmerLoading.rectangular(width: 40, height: 20),
              title: ShimmerLoading.rectangular(width: 150, height: 20),
              trailing: ShimmerLoading.rectangular(width: 60, height: 20),
            ),
          ),
        ),
      ],
    );
  }
}
