import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:version/core/constants/app_colors.dart';
import 'package:version/core/theme/text_styles.dart';
import 'package:version/features/goals/providers/goal_providers.dart';
import 'package:version/features/goals/widgets/circular_progress_ring.dart';
import 'package:version/features/goals/widgets/deposit_history_list.dart';
import 'package:version/features/goals/widgets/milestone_timeline.dart';
import 'package:version/models/deposit.dart';
import 'package:version/models/goal.dart';
import 'package:version/navigation/route_names.dart';
import 'package:version/services/supabase_service.dart';

class GoalDetailScreen extends ConsumerWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(goalProvider(goalId));
    final depositsAsync = ref.watch(depositsProvider(goalId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RouteNames.goals);
            }
          },
        ),
      ),
      body: goalAsync.when(
        data: (goal) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(goal.emoji ?? '🎯',
                          style: const TextStyle(fontSize: 44)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(goal.name, style: AppTextStyles.h1),
                            if (goal.deadline != null)
                              Text(
                                'Due: ${DateFormat.yMMMd().format(goal.deadline!)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textMid),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: CircularProgressRing(
                  progress: goal.targetAmount > 0
                      ? goal.savedAmount / goal.targetAmount
                      : 0,
                  label: 'Progress',
                  size: 190,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saved',
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 2),
                          Text(
                            '\$${goal.savedAmount.toStringAsFixed(2)}',
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.primaryGoldDark,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Target',
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 2),
                          Text(
                            '\$${goal.targetAmount.toStringAsFixed(2)}',
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text('Milestones', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              MilestoneTimeline(
                progressPercent: goal.targetAmount > 0
                    ? (goal.savedAmount / goal.targetAmount) * 100
                    : 0,
              ),
              const SizedBox(height: 22),
              Text('Deposit History', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              depositsAsync.when(
                data: (deposits) => deposits.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 40, color: AppColors.textLight),
                              SizedBox(height: 12),
                              Text('No deposits yet'),
                            ],
                          ),
                        ),
                      )
                    : DepositHistoryList(deposits: deposits),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.dangerRed),
                        const SizedBox(height: 8),
                        Text('Error loading deposits: $err'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.dangerRed),
              const SizedBox(height: 12),
              const Text('Unable to load goal'),
              const SizedBox(height: 6),
              Text(
                err.toString(),
                style: const TextStyle(fontSize: 12, color: AppColors.textMid),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.refresh(goalProvider(goalId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: goalAsync.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDepositSheet(
                context,
                ref,
                goalId,
                goalAsync.value!,
              ),
              label: const Text('Add Deposit'),
              icon: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  void _showAddDepositSheet(
    BuildContext context,
    WidgetRef ref,
    String goalId,
    Goal goal,
  ) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Deposit', style: AppTextStyles.h2),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: formKey,
              child: TextFormField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (\$)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (amount > goal.targetAmount - goal.savedAmount) {
                    return 'Amount exceeds remaining target';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Remaining: \$${(goal.targetAmount - goal.savedAmount).toStringAsFixed(2)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMid),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final amount = double.parse(amountController.text);
                    final userId = supabase.auth.currentUser?.id;

                    if (userId == null) {
                      return;
                    }

                    try {
                      final newDeposit = Deposit(
                        id: const Uuid().v4(),
                        goalId: goalId,
                        userId: userId,
                        amount: amount,
                        createdAt: DateTime.now(),
                        coinsEarned: 15,
                        xpEarned: 10,
                      );

                      await ref
                          .read(goalRepositoryProvider)
                          .addDeposit(newDeposit)
                          .then((_) async {
                        final updatedGoal = Goal(
                          id: goal.id,
                          userId: goal.userId,
                          name: goal.name,
                          category: goal.category,
                          emoji: goal.emoji,
                          colorTheme: goal.colorTheme,
                          targetAmount: goal.targetAmount,
                          savedAmount: goal.savedAmount + amount,
                          deadline: goal.deadline,
                          status: goal.status,
                          createdAt: goal.createdAt,
                        );
                        await ref
                            .read(goalRepositoryProvider)
                            .updateGoal(updatedGoal);
                        if (context.mounted) {
                          ref.invalidate(goalProvider(goalId));
                          ref.invalidate(depositsProvider(goalId));
                          Navigator.of(context, rootNavigator: false).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Added \$${amount.toStringAsFixed(2)} to ${goal.name}'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      });
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  }
                },
                child: const Text('Add Deposit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
