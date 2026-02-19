import 'package:hive_flutter/hive_flutter.dart';
import 'package:version/features/auth/repositories/user_repository.dart';
import 'package:version/features/goals/repositories/goal_repository.dart';
import 'package:version/services/storage_service.dart';

class OfflineQueueService {
  OfflineQueueService._internal();
  static final OfflineQueueService instance = OfflineQueueService._internal();

  static const _pendingActionsKey = 'pending_actions';

  Box get _box => Hive.box(StorageService.offlineQueueBox);

  List<Map<String, dynamic>> getPendingActions() {
    final raw = _box.get(_pendingActionsKey, defaultValue: <dynamic>[]);
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _save(List<Map<String, dynamic>> actions) async {
    await _box.put(_pendingActionsKey, actions);
  }

  Future<void> enqueueCheckIn() async {
    final actions = getPendingActions();
    final alreadyQueuedCheckIn = actions.any((a) => a['type'] == 'checkin');
    if (alreadyQueuedCheckIn) {
      return;
    }

    actions.add({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'type': 'checkin',
      'created_at': DateTime.now().toIso8601String(),
    });

    await _save(actions);
  }

  Future<void> enqueueDeposit({
    required String goalId,
    required double amount,
    String? note,
  }) async {
    final actions = getPendingActions();
    actions.add({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'type': 'deposit',
      'goal_id': goalId,
      'amount': amount,
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _save(actions);
  }

  Future<int> processQueue() async {
    final pending = getPendingActions();
    if (pending.isEmpty) {
      return 0;
    }

    final userRepository = UserRepository();
    final goalRepository = GoalRepository();
    final remaining = <Map<String, dynamic>>[];
    var processed = 0;

    for (final action in pending) {
      try {
        final type = action['type'];
        if (type == 'checkin') {
          await userRepository.processCheckIn();
          processed++;
          continue;
        }

        if (type == 'deposit') {
          final goalId = action['goal_id']?.toString();
          final amount = (action['amount'] as num?)?.toDouble();
          final note = action['note']?.toString();

          if (goalId == null || amount == null || amount <= 0) {
            continue;
          }

          await goalRepository.processDeposit(
            goalId: goalId,
            amount: amount,
            note: note?.isEmpty == true ? null : note,
          );
          processed++;
          continue;
        }

        remaining.add(action);
      } catch (_) {
        remaining.add(action);
      }
    }

    await _save(remaining);
    return processed;
  }
}
