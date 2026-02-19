import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:version/core/constants/app_colors.dart';
import 'package:version/core/widgets/shimmer_loading.dart';
import 'package:version/features/goals/providers/goal_providers.dart';
import 'package:version/features/goals/widgets/add_edit_goal_sheet.dart';
import 'package:version/models/goal.dart';
import 'package:version/navigation/route_names.dart';
import 'package:version/services/supabase_service.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final filter = ref.watch(goalsFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddGoalSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: GoalsFilter.values.map((f) {
                    final label = f.name[0].toUpperCase() + f.name.substring(1);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: filter == f,
                        onSelected: (_) {
                          ref.read(goalsFilterProvider.notifier).state = f;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Expanded(
            child: goalsAsync.when(
              data: (goals) => goals.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.flag_outlined,
                                    size: 46, color: AppColors.textLight),
                                const SizedBox(height: 10),
                                Text('No goals yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 6),
                                Text(
                                  'Create your first goal to start saving with structure.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.textMid),
                                ),
                                const SizedBox(height: 14),
                                FilledButton(
                                  onPressed: () =>
                                      _showAddGoalSheet(context, ref),
                                  child: const Text('Create Goal'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.refresh(goalsProvider.future),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                        itemCount: goals.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final goal = goals[index];
                          return _GoalTileCard(
                            goal: goal,
                            onTap: () => context
                                .push('${RouteNames.goalDetails}/${goal.id}'),
                          );
                        },
                      ),
                    ),
              loading: () => _buildGoalsShimmer(),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: AppColors.dangerRed),
                          const SizedBox(height: 10),
                          const Text('Unable to load goals'),
                          const SizedBox(height: 6),
                          Text(
                            err.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMid,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.tonal(
                            onPressed: () => ref.refresh(goalsProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              ShimmerLoading.circular(size: 40),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading.rectangular(width: 150, height: 16),
                  SizedBox(height: 8),
                  ShimmerLoading.rectangular(width: 100, height: 12),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _showAddGoalSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddEditGoalSheet(
        onSubmit: ({
          required String name,
          required String category,
          required double targetAmount,
          required double savedAmount,
          String? emoji,
          String? colorTheme,
          DateTime? deadline,
        }) async {
          final userId = supabase.auth.currentUser?.id;

          if (userId == null) return;

          final newGoal = Goal(
            id: const Uuid().v4(),
            userId: userId,
            name: name,
            category: category,
            emoji: emoji ?? '🎯',
            targetAmount: targetAmount,
            savedAmount: savedAmount,
            deadline: deadline,
            status: GoalStatus.active,
            colorTheme: colorTheme,
            createdAt: DateTime.now(),
          );

          try {
            await ref.read(goalsActionsProvider).addGoal(newGoal);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goal created!')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error creating goal: $e')),
              );
            }
          }
        },
      ),
    );
  }
}

class _GoalTileCard extends StatelessWidget {
  const _GoalTileCard({
    required this.goal,
    required this.onTap,
  });

  final Goal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent =
        goal.targetAmount > 0 ? goal.savedAmount / goal.targetAmount : 0;
    final clampedPercent = percent.clamp(0.0, 1.0);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(goal.emoji ?? '🎯',
                      style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      goal.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textLight),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: clampedPercent.toDouble(),
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: AppColors.cardGray,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${goal.savedAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${(clampedPercent * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryGoldDark,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
