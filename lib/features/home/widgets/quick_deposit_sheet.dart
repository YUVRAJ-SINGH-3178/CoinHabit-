import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:version/core/constants/app_colors.dart';
import 'package:version/features/goals/providers/goal_providers.dart';
import 'package:version/models/goal.dart';
import 'package:version/services/offline_queue_service.dart';
import 'package:version/services/offline_service.dart';

class QuickDepositSheet extends ConsumerStatefulWidget {
  const QuickDepositSheet({super.key});

  @override
  ConsumerState<QuickDepositSheet> createState() => _QuickDepositSheetState();
}

class _QuickDepositSheetState extends ConsumerState<QuickDepositSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedGoalId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting ||
        !_formKey.currentState!.validate() ||
        _selectedGoalId == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final amount = double.parse(_amountController.text.trim());

      if (!OfflineService.instance.isOnline) {
        await OfflineQueueService.instance.enqueueDeposit(
          goalId: _selectedGoalId!,
          amount: amount,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You are offline. Deposit queued and will sync automatically.'),
          ),
        );
        return;
      }

      final result = await ref.read(goalsActionsProvider).addDeposit(
            goalId: _selectedGoalId!,
            amount: amount,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      final milestone = result['milestone_hit'];
      final completed = result['goal_completed'] == true;
      final extra = milestone != null
          ? ' Milestone $milestone% reached!'
          : completed
              ? ' Goal completed!'
              : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deposit added successfully.$extra')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add deposit: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: goalsAsync.when(
          data: (goals) {
            final activeGoals = goals
                .where((goal) => goal.status == GoalStatus.active)
                .toList();
            if (activeGoals.isEmpty) {
              return const SizedBox(
                height: 160,
                child: Center(
                  child: Text('No active goals available for quick deposit.'),
                ),
              );
            }

            _selectedGoalId ??= activeGoals.first.id;

            return Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Deposit',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGoalId,
                    decoration: const InputDecoration(labelText: 'Goal'),
                    items: activeGoals
                        .map(
                          (goal) => DropdownMenuItem<String>(
                            value: goal.id,
                            child: Text('${goal.emoji ?? '🎯'} ${goal.name}'),
                          ),
                        )
                        .toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() => _selectedGoalId = value);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter amount';
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add Deposit'),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SizedBox(
            height: 180,
            child: Center(
              child: Text('Failed to load goals: $error'),
            ),
          ),
        ),
      ),
    );
  }
}
