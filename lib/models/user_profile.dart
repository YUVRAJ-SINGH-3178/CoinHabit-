
import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.level,
    required this.xp,
    required this.coins,
    required this.streakCurrent,
    required this.streakLongest,
    required this.streakFreezes,
    this.lastCheckinDate,
    this.notificationTime,
    required this.updatedAt,
  });

  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final int level;
  final int xp;
  final int coins;
  final int streakCurrent;
  final int streakLongest;
  final int streakFreezes;
  final DateTime? lastCheckinDate;
  final String? notificationTime;
  final DateTime updatedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      level: json['level'] as int,
      xp: json['xp'] as int,
      coins: json['coins'] as int,
      streakCurrent: json['streak_current'] as int,
      streakLongest: json['streak_longest'] as int,
      streakFreezes: json['streak_freezes'] as int,
      lastCheckinDate: json['last_checkin_date'] != null
          ? DateTime.parse(json['last_checkin_date'])
          : null,
      notificationTime: json['notification_time'] as String?,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
