import 'package:flutter/foundation.dart';

@immutable
class Badge {
  const Badge({
    required this.id,
    required this.userId,
    required this.badgeKey,
    required this.badgeName,
    required this.badgeRarity,
    required this.earnedAt,
  });

  final String id;
  final String userId;
  final String badgeKey;
  final String badgeName;
  final String badgeRarity;
  final DateTime earnedAt;

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      badgeKey: json['badge_key'] as String,
      badgeName: json['badge_name'] as String,
      badgeRarity: json['badge_rarity'] as String,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }
}
