import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:version/models/deposit.dart';
import 'package:version/models/goal.dart';
import 'package:version/services/supabase_service.dart';

class GoalRepository {
  final _goalsBox = Hive.box('goals');

  bool _isMissingRelationError(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST205' ||
        message.contains("could not find the table") ||
        message.contains("relation") && message.contains("does not exist");
  }

  Future<List<Goal>> getGoals({
    bool forceRefresh = false,
    GoalStatus? status,
    int limit = 100,
    int offset = 0,
  }) async {
    // Try to load from cache first
    final cacheKey =
        status == null ? 'user_goals_all' : 'user_goals_${status.name}';
    final cachedGoals = _goalsBox.get(cacheKey);
    if (!forceRefresh && offset == 0 && cachedGoals != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedGoals);
        return decoded.map((g) => Goal.fromJson(g)).toList();
      } catch (e) {
        // If cache is corrupt, proceed to fetch from network
      }
    }

    // Fetch from network
    try {
      final supabaseQuery = supabase.from('goals').select();

      final orderedQuery = status == null
          ? supabaseQuery.order('created_at', ascending: false)
          : supabaseQuery
              .eq('status', status.name)
              .order('created_at', ascending: false);

      final response = await orderedQuery.range(offset, offset + limit - 1);

      // Save to cache
      if (offset == 0) {
        await _goalsBox.put(cacheKey, jsonEncode(response));
      }

      return (response as List).map((e) => Goal.fromJson(e)).toList();
    } on PostgrestException catch (error) {
      if (_isMissingRelationError(error)) {
        return [];
      }
      rethrow;
    }
  }

  // ... (rest of the methods remain the same)

  Future<Goal> getGoal(String goalId) async {
    final response =
        await supabase.from('goals').select().eq('id', goalId).single();
    return Goal.fromJson(response);
  }

  Future<void> addGoal(Goal goal) async {
    await supabase.from('goals').insert(goal.toJson());
    await _invalidateGoalsCache();
  }

  Future<void> updateGoal(Goal goal) async {
    await supabase.from('goals').update(goal.toJson()).eq('id', goal.id);
    await _invalidateGoalsCache();
  }

  Future<void> deleteGoal(String goalId) async {
    await supabase.from('goals').delete().eq('id', goalId);
    await _invalidateGoalsCache();
  }

  Future<List<Deposit>> getDeposits(String goalId) async {
    try {
      final response = await supabase
          .from('deposits')
          .select()
          .eq('goal_id', goalId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => Deposit.fromJson(e)).toList();
    } on PostgrestException catch (error) {
      if (_isMissingRelationError(error)) {
        return [];
      }
      rethrow;
    }
  }

  Future<void> addDeposit(Deposit deposit) async {
    await supabase.from('deposits').insert(deposit.toJson());
    await _invalidateGoalsCache();
  }

  Future<Map<String, dynamic>> processDeposit({
    required String goalId,
    required double amount,
    String? note,
  }) async {
    try {
      final response = await supabase.rpc('process_deposit', params: {
        'p_goal_id': goalId,
        'p_amount': amount,
        'p_note': note,
      });

      await _invalidateGoalsCache();
      return response as Map<String, dynamic>;
    } catch (_) {
      final goal = await getGoal(goalId);
      final userId = supabase.auth.currentUser!.id;
      final now = DateTime.now();
      final newSavedAmount = goal.savedAmount + amount;
      final completionPercentage =
          ((newSavedAmount / goal.targetAmount) * 100).clamp(0, 100);

      final milestoneHit = _detectMilestone(
        before: ((goal.savedAmount / goal.targetAmount) * 100).toDouble(),
        after: completionPercentage.toDouble(),
      );

      final updatedGoal = Goal(
        id: goal.id,
        userId: goal.userId,
        name: goal.name,
        category: goal.category,
        emoji: goal.emoji,
        targetAmount: goal.targetAmount,
        savedAmount: newSavedAmount,
        deadline: goal.deadline,
        status:
            completionPercentage >= 100 ? GoalStatus.completed : goal.status,
        colorTheme: goal.colorTheme,
        createdAt: goal.createdAt,
        completedAt: completionPercentage >= 100 ? now : goal.completedAt,
      );

      final deposit = Deposit(
        id: const Uuid().v4(),
        goalId: goalId,
        userId: userId,
        amount: amount,
        note: note,
        coinsEarned: milestoneHit == null ? 15 : 65,
        xpEarned: milestoneHit == null ? 10 : 40,
        createdAt: now,
      );

      await addDeposit(deposit);
      await updateGoal(updatedGoal);

      return {
        'success': true,
        'milestone_hit': milestoneHit,
        'goal_completed': completionPercentage >= 100,
        'coins_earned': deposit.coinsEarned,
        'xp_earned': deposit.xpEarned,
      };
    }
  }

  int? _detectMilestone({required double before, required double after}) {
    const milestones = [25, 50, 75, 100];
    for (final milestone in milestones) {
      if (before < milestone && after >= milestone) {
        return milestone;
      }
    }
    return null;
  }

  Future<void> _invalidateGoalsCache() async {
    await _goalsBox.delete('user_goals_all');
    await _goalsBox.delete('user_goals_active');
    await _goalsBox.delete('user_goals_completed');
    await _goalsBox.delete('user_goals_paused');
  }

  Future<List<double>> getWeeklySavings(String userId) async {
    try {
      final response = await supabase.rpc(
        'get_weekly_savings',
        params: {'p_user_id': userId},
      );

      final weeklyTotals = List<double>.filled(7, 0);
      if (response is List) {
        for (final item in response) {
          if (item is! Map<String, dynamic>) {
            continue;
          }

          final weekdayValue = item['weekday'] ?? item['day_index'];
          final amountValue =
              item['total_amount'] ?? item['amount'] ?? item['total'];
          final weekday = weekdayValue is int
              ? weekdayValue
              : int.tryParse(weekdayValue?.toString() ?? '');

          if (weekday == null || weekday < 1 || weekday > 7) {
            continue;
          }

          weeklyTotals[weekday - 1] = (amountValue as num?)?.toDouble() ?? 0;
        }
      }
      return weeklyTotals;
    } on PostgrestException catch (error) {
      if (error.code != 'PGRST202' && !_isMissingRelationError(error)) {
        rethrow;
      }

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
      final response = await supabase
          .from('deposits')
          .select('amount, created_at')
          .eq('user_id', userId)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', now.toIso8601String());

      final weeklyTotals = List<double>.filled(7, 0);
      for (final item in (response as List)) {
        final map = item as Map<String, dynamic>;
        final createdAt = DateTime.parse(map['created_at'] as String).toLocal();
        final weekdayIndex = createdAt.weekday - 1;
        weeklyTotals[weekdayIndex] += (map['amount'] as num).toDouble();
      }

      return weeklyTotals;
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlySavings(String userId) async {
    try {
      final response = await supabase.rpc(
        'get_monthly_savings',
        params: {'p_user_id': userId},
      );
      return (response as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST202' || _isMissingRelationError(error)) {
        return [];
      }
      rethrow;
    }
  }
}
