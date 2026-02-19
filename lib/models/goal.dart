import 'package:flutter/foundation.dart';

enum GoalStatus { active, completed, paused }

@immutable
class Goal {
  const Goal({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.emoji,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
    required this.status,
    this.colorTheme,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String category;
  final String? emoji;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final GoalStatus status;
  final String? colorTheme;
  final DateTime createdAt;
  final DateTime? completedAt;

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      emoji: json['emoji'] as String?,
      targetAmount: (json['target_amount'] as num).toDouble(),
      savedAmount: (json['saved_amount'] as num).toDouble(),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      status: GoalStatus.values.firstWhere((e) => e.name == json['status']),
      colorTheme: json['color_theme'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'emoji': emoji,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      'deadline': deadline?.toIso8601String(),
      'status': status.name,
      'color_theme': colorTheme,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
