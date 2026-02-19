import 'package:flutter/material.dart';
import 'package:version/models/goal.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;

  const GoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: goal.savedAmount / goal.targetAmount,
            ),
            const SizedBox(height: 8),
            Text('\$${goal.savedAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
