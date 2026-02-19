import 'package:version/models/badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version/services/supabase_service.dart';

class BadgeRepository {
  // In a real app, this would likely come from a database table
  // For now, we define them statically
  final List<Map<String, String>> allBadges = [
    {
      'key': 'first_deposit',
      'name': 'First Deposit',
      'description': 'Make your first deposit',
      'rarity': 'common'
    },
    {
      'key': 'week_warrior',
      'name': 'Week Warrior',
      'description': 'Achieve a 7-day streak',
      'rarity': 'common'
    },
    {
      'key': 'month_master',
      'name': 'Month Master',
      'description': 'Achieve a 30-day streak',
      'rarity': 'rare'
    },
    {
      'key': 'goal_crusher',
      'name': 'Goal Crusher',
      'description': 'Complete your first goal',
      'rarity': 'rare'
    },
    {
      'key': 'triple_threat',
      'name': 'Triple Threat',
      'description': 'Have 3 active goals at once',
      'rarity': 'uncommon'
    },
    {
      'key': 'centurion',
      'name': 'Centurion',
      'description': 'Make 100 total deposits',
      'rarity': 'epic'
    },
    {
      'key': 'big_saver',
      'name': 'Big Saver',
      'description': 'Save over \$1000 in total',
      'rarity': 'epic'
    },
  ];

  bool _isMissingRelationError(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST205' ||
        message.contains("could not find the table") ||
        (message.contains('relation') && message.contains('does not exist'));
  }

  Future<List<Badge>> getEarnedBadges(String userId) async {
    try {
      final response = await supabase
          .from('badges')
          .select()
          .eq('user_id', userId)
          .order('earned_at', ascending: false);
      return (response as List).map((e) => Badge.fromJson(e)).toList();
    } on PostgrestException catch (error) {
      if (_isMissingRelationError(error)) {
        return [];
      }
      rethrow;
    }
  }

  Future<void> syncBadges(String userId) async {
    try {
      final earned = await getEarnedBadges(userId);
      final earnedKeys = earned.map((badge) => badge.badgeKey).toSet();

      final profile = await supabase
          .from('profiles')
          .select('streak_current')
          .eq('id', userId)
          .single();

      final depositsResponse = await supabase
          .from('deposits')
          .select('amount')
          .eq('user_id', userId);

      final goalsResponse =
          await supabase.from('goals').select('status').eq('user_id', userId);

      final streakCurrent = (profile['streak_current'] as num?)?.toInt() ?? 0;
      final deposits = (depositsResponse as List).cast<Map<String, dynamic>>();
      final goals = (goalsResponse as List).cast<Map<String, dynamic>>();

      final totalDeposits = deposits.length;
      final totalSaved = deposits.fold<double>(
        0,
        (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0),
      );
      final completedGoals =
          goals.where((goal) => goal['status'] == 'completed').length;
      final activeGoals =
          goals.where((goal) => goal['status'] == 'active').length;

      final unlockKeys = <String>{};
      if (totalDeposits >= 1) unlockKeys.add('first_deposit');
      if (streakCurrent >= 7) unlockKeys.add('week_warrior');
      if (streakCurrent >= 30) unlockKeys.add('month_master');
      if (completedGoals >= 1) unlockKeys.add('goal_crusher');
      if (activeGoals >= 3) unlockKeys.add('triple_threat');
      if (totalDeposits >= 100) unlockKeys.add('centurion');
      if (totalSaved >= 1000) unlockKeys.add('big_saver');

      final newKeys = unlockKeys.where((key) => !earnedKeys.contains(key));
      if (newKeys.isEmpty) {
        return;
      }

      final nowIso = DateTime.now().toIso8601String();
      final rows = allBadges
          .where((badge) => newKeys.contains(badge['key']))
          .map(
            (badge) => {
              'user_id': userId,
              'badge_key': badge['key'],
              'badge_name': badge['name'],
              'badge_rarity': badge['rarity'],
              'earned_at': nowIso,
            },
          )
          .toList();

      if (rows.isNotEmpty) {
        await supabase.from('badges').insert(rows);
      }
    } on PostgrestException catch (error) {
      if (_isMissingRelationError(error)) {
        return;
      }
      rethrow;
    }
  }
}
