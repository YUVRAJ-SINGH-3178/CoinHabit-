import 'package:flutter/foundation.dart';

@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    this.username,
    this.avatarUrl,
    required this.coinsThisWeek,
    this.rank,
  });

  final String userId;
  final String? username;
  final String? avatarUrl;
  final int coinsThisWeek;
  final int? rank;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coinsThisWeek: json['coins_this_week'] as int,
      rank: json['rank'] as int?,
    );
  }
}
