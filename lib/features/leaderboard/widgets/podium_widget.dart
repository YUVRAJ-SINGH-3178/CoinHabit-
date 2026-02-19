import 'package:flutter/material.dart';
import 'package:version/core/constants/colors.dart';
import 'package:version/models/leaderboard_entry.dart';

class PodiumWidget extends StatelessWidget {
  final List<LeaderboardEntry> topThree;

  const PodiumWidget({super.key, required this.topThree});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 265,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 2nd Place
          if (topThree.length > 1)
            _buildPodiumEntry(context, topThree[1], 150, '🥈'),
          // 1st Place
          if (topThree.isNotEmpty)
            _buildPodiumEntry(context, topThree[0], 200, '🥇'),
          // 3rd Place
          if (topThree.length > 2)
            _buildPodiumEntry(context, topThree[2], 120, '🥉'),
        ],
      ),
    );
  }

  Widget _buildPodiumEntry(BuildContext context, LeaderboardEntry entry,
      double height, String medal) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(medal, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.cardGray,
          child: Text(entry.username?[0].toUpperCase() ?? 'U',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 6),
        Text(entry.username ?? 'Anonymous',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          height: height,
          width: 84,
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Text(
              entry.coinsThisWeek.toString(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}
