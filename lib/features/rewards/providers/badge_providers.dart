import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:version/features/rewards/repositories/badge_repository.dart';
import 'package:version/models/badge.dart';
import 'package:version/services/supabase_service.dart';

// Provides the repository
final badgeRepositoryProvider = Provider((ref) => BadgeRepository());

// Provides the list of all possible badges (static data)
final allBadgesProvider = Provider<List<Map<String, String>>>((ref) {
  return ref.watch(badgeRepositoryProvider).allBadges;
});

final syncBadgesProvider = FutureProvider<void>((ref) async {
  final userId = supabase.auth.currentUser!.id;
  final repository = ref.watch(badgeRepositoryProvider);
  await repository.syncBadges(userId);
});

final earnedBadgesProvider = FutureProvider<List<Badge>>((ref) async {
  final userId = supabase.auth.currentUser!.id;
  final repository = ref.watch(badgeRepositoryProvider);
  await repository.syncBadges(userId);
  return repository.getEarnedBadges(userId);
});
