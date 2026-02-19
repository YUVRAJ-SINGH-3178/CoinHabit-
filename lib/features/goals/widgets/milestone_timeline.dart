import 'package:flutter/material.dart';
import 'package:version/core/constants/app_colors.dart';

class MilestoneTimeline extends StatelessWidget {
  const MilestoneTimeline({
    super.key,
    required this.progressPercent,
  });

  final double progressPercent;

  @override
  Widget build(BuildContext context) {
    const milestones = [25, 50, 75, 100];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: milestones.map((milestone) {
        final isDone = progressPercent >= milestone;
        return Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor:
                  isDone ? AppColors.primaryGold : AppColors.cardGray,
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '$milestone',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textDark),
                    ),
            ),
            const SizedBox(height: 6),
            Text('$milestone%', style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}
