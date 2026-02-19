import 'package:flutter/foundation.dart';

@immutable
class Deposit {
  const Deposit({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.amount,
    this.note,
    required this.coinsEarned,
    required this.xpEarned,
    required this.createdAt,
  });

  final String id;
  final String goalId;
  final String userId;
  final double amount;
  final String? note;
  final int coinsEarned;
  final int xpEarned;
  final DateTime createdAt;

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      coinsEarned: json['coins_earned'] as int,
      xpEarned: json['xp_earned'] as int,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'user_id': userId,
      'amount': amount,
      'note': note,
      'coins_earned': coinsEarned,
      'xp_earned': xpEarned,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
