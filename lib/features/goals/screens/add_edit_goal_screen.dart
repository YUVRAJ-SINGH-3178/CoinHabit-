import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:version/core/constants/app_colors.dart';
import 'package:version/features/goals/providers/goal_providers.dart';
import 'package:version/models/goal.dart';
import 'package:version/services/supabase_service.dart';

class AddEditGoalScreen extends ConsumerStatefulWidget {
  final Goal? goal;
  const AddEditGoalScreen({super.key, this.goal});

  @override
  ConsumerState<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends ConsumerState<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _category;
  late double _targetAmount;

  @override
  void initState() {
    super.initState();
    _name = widget.goal?.name ?? '';
    _category = widget.goal?.category ?? 'other';
    _targetAmount = widget.goal?.targetAmount ?? 0.0;
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newGoal = Goal(
        id: widget.goal?.id ?? const Uuid().v4(),
        userId: supabase.auth.currentUser!.id,
        name: _name,
        category: _category,
        targetAmount: _targetAmount,
        savedAmount: widget.goal?.savedAmount ?? 0.0,
        status: widget.goal?.status ?? GoalStatus.active,
        createdAt: widget.goal?.createdAt ?? DateTime.now(),
      );

      if (widget.goal == null) {
        await ref.read(goalRepositoryProvider).addGoal(newGoal);
      } else {
        await ref.read(goalRepositoryProvider).updateGoal(newGoal);
      }

      ref.invalidate(goalsProvider);
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal == null ? 'Add Goal' : 'Edit Goal'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.goal == null
                          ? 'Define your new savings goal'
                          : 'Update goal details',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textMid),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(
                        labelText: 'Goal Name',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a name' : null,
                      onSaved: (value) => _name = value!,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: _targetAmount == 0
                          ? ''
                          : _targetAmount.toStringAsFixed(2),
                      decoration: const InputDecoration(
                        labelText: 'Target Amount',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value.trim());
                        if (amount == null || amount <= 0) {
                          return 'Enter a valid target amount';
                        }
                        return null;
                      },
                      onSaved: (value) => _targetAmount = double.parse(value!),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(
                        widget.goal == null ? 'Add Goal' : 'Save Changes',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
