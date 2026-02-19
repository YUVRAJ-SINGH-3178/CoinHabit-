import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:version/features/goals/repositories/goal_repository.dart';
import 'package:version/features/rewards/providers/badge_providers.dart';
import 'package:version/models/deposit.dart';
import 'package:version/models/goal.dart';
import 'package:version/services/supabase_service.dart';

enum GoalsFilter { all, active, completed, paused }

final goalRepositoryProvider = Provider((ref) => GoalRepository());

final goalsFilterProvider =
    StateProvider<GoalsFilter>((ref) => GoalsFilter.all);

final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  final goalRepository = ref.watch(goalRepositoryProvider);
  final filter = ref.watch(goalsFilterProvider);

  final goals = await goalRepository.getGoals(forceRefresh: true);
  if (filter == GoalsFilter.all) {
    return goals;
  }

  final targetStatus = switch (filter) {
    GoalsFilter.all => null,
    GoalsFilter.active => GoalStatus.active,
    GoalsFilter.completed => GoalStatus.completed,
    GoalsFilter.paused => GoalStatus.paused,
  };

  return goals.where((goal) => goal.status == targetStatus).toList();
});

final goalProvider = FutureProvider.family<Goal, String>((ref, goalId) async {
  final goalRepository = ref.watch(goalRepositoryProvider);
  return goalRepository.getGoal(goalId);
});

final depositsProvider =
    FutureProvider.family<List<Deposit>, String>((ref, goalId) async {
  final goalRepository = ref.watch(goalRepositoryProvider);
  return goalRepository.getDeposits(goalId);
});

final monthlySavingsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final userId = supabase.auth.currentUser!.id;
  return ref.watch(goalRepositoryProvider).getMonthlySavings(userId);
});

final completedGoalsCountProvider = FutureProvider<int>((ref) async {
  final goals = await ref
      .watch(goalRepositoryProvider)
      .getGoals(status: GoalStatus.completed, forceRefresh: true);
  return goals.length;
});

final weeklySavingsProvider = FutureProvider<List<double>>((ref) {
  final userId = supabase.auth.currentUser!.id;
  return ref.watch(goalRepositoryProvider).getWeeklySavings(userId);
});

final goalsActionsProvider = Provider((ref) => GoalsActions(ref));

class GoalsActions {
  GoalsActions(this._ref);

  final Ref _ref;

  GoalRepository get _repository => _ref.read(goalRepositoryProvider);

  Future<void> refreshGoals() async {
    _ref.invalidate(goalsProvider);
    await _ref.read(goalsProvider.future);
  }

  Future<void> addGoal(Goal goal) async {
    await _repository.addGoal(goal);
    await _syncBadges();
    _ref.invalidate(goalsProvider);
  }

  Future<void> updateGoal(Goal goal) async {
    await _repository.updateGoal(goal);
    await _syncBadges();
    _ref.invalidate(goalsProvider);
    _ref.invalidate(goalProvider(goal.id));
  }

  Future<void> deleteGoal(String goalId) async {
    await _repository.deleteGoal(goalId);
    _ref.invalidate(goalsProvider);
    _ref.invalidate(goalProvider(goalId));
    _ref.invalidate(depositsProvider(goalId));
  }

  Future<Map<String, dynamic>> addDeposit({
    required String goalId,
    required double amount,
    String? note,
  }) async {
    final result = await _repository.processDeposit(
      goalId: goalId,
      amount: amount,
      note: note,
    );
    await _syncBadges();
    _ref.invalidate(goalsProvider);
    _ref.invalidate(goalProvider(goalId));
    _ref.invalidate(depositsProvider(goalId));
    return result;
  }

  Future<void> _syncBadges() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    try {
      await _ref.read(badgeRepositoryProvider).syncBadges(userId);
      _ref.invalidate(earnedBadgesProvider);
    } catch (_) {}
  }
}
