import 'package:flutter/foundation.dart';

@immutable
class Checkin {
  const Checkin({
    required this.id,
    required this.userId,
    required this.checkinDate,
    required this.coinsEarned,
    required this.xpEarned,
    this.streakCount,
    required this.freezeUsed,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final DateTime checkinDate;
  final int coinsEarned;
  final int xpEarned;
  final int? streakCount;
  final bool freezeUsed;
  final DateTime createdAt;

  factory Checkin.fromJson(Map<String, dynamic> json) {
    return Checkin(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      checkinDate: DateTime.parse(json['checkin_date'] as String),
      coinsEarned: json['coins_earned'] as int,
      xpEarned: json['xp_earned'] as int,
      streakCount: json['streak_count'] as int?,
      freezeUsed: json['freeze_used'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
