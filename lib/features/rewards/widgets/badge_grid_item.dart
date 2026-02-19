import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:version/core/constants/colors.dart';

class BadgeGridItem extends StatelessWidget {
  final Map<String, String> badgeInfo;
  final bool isEarned;

  const BadgeGridItem({
    super.key,
    required this.badgeInfo,
    required this.isEarned,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showBadgeDetails(context),
      child: Card(
        color: isEarned ? AppColors.cardWhite : AppColors.cardGray,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isEarned
                  ? const Icon(Icons.shield,
                          color: AppColors.primaryGold, size: 40)
                      .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true))
                      .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.05, 1.05),
                          duration: 900.ms)
                  : Icon(Icons.lock, color: Colors.grey[600], size: 40),
              const SizedBox(height: 6),
              Expanded(
                child: Center(
                  child: Text(
                    badgeInfo['name']!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isEarned ? AppColors.textDark : AppColors.textMid,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(badgeInfo['name']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badgeInfo['description']!),
            const SizedBox(height: 8),
            Chip(
                label: Text(badgeInfo['rarity']!),
                backgroundColor: AppColors.primaryGold.withValues(alpha: 0.2)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
