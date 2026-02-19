import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:version/models/leaderboard_entry.dart';
import 'package:version/services/supabase_service.dart';

class LeaderboardRepository {
  bool _isMissingRelationError(PostgrestException error) {
    final message = error.message.toLowerCase();
    return error.code == 'PGRST205' ||
        message.contains("could not find the table") ||
        (message.contains('relation') && message.contains('does not exist'));
  }

  Stream<List<LeaderboardEntry>> getWeeklyLeaderboard() {
    final controller = StreamController<List<LeaderboardEntry>>();

    // Fetch initial data
    Future<void> fetchAndPushData() async {
      try {
        final now = DateTime.now();
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));

        List response;
        try {
          response = await supabase
              .from('leaderboard_snapshots')
              .select()
              .gte('week_start', startOfWeek.toIso8601String())
              .order('rank', ascending: true)
              .limit(100) as List;
        } on PostgrestException {
          response = await supabase
              .from('leaderboard_snapshots')
              .select()
              .order('rank', ascending: true)
              .limit(100) as List;
        }

        final entries =
            response.map((e) => LeaderboardEntry.fromJson(e)).toList();
        if (!controller.isClosed) {
          controller.add(entries);
        }
      } catch (e) {
        if (e is PostgrestException && _isMissingRelationError(e)) {
          if (!controller.isClosed) {
            controller.add([]);
          }
          return;
        }

        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    fetchAndPushData();

    // Subscribe to realtime updates
    final subscription = supabase
        .channel('public:leaderboard_snapshots')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leaderboard_snapshots',
          callback: (_) => fetchAndPushData(),
        )
        .subscribe();

    // On stream close, cancel the Supabase subscription
    controller.onCancel = () {
      supabase.removeChannel(subscription);
    };

    return controller.stream;
  }
}
