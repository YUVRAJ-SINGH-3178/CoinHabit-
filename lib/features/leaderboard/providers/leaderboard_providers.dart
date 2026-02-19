import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:version/features/leaderboard/repositories/leaderboard_repository.dart';
import 'package:version/models/leaderboard_entry.dart';

// Provides the repository
final leaderboardRepositoryProvider = Provider((ref) => LeaderboardRepository());

// Provides the live stream of weekly leaderboard data
final weeklyLeaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.getWeeklyLeaderboard();
});
