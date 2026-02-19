import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:version/models/deposit.dart';

class DepositHistoryList extends StatelessWidget {
  const DepositHistoryList({
    super.key,
    required this.deposits,
  });

  final List<Deposit> deposits;

  @override
  Widget build(BuildContext context) {
    if (deposits.isEmpty) {
      return const Center(
          child: Text('No deposits yet. Tap Add Deposit to start!'));
    }

    return ListView.separated(
      itemCount: deposits.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final deposit = deposits[index];
        return ListTile(
          leading: const Icon(Icons.savings_outlined),
          title: Text('\$${deposit.amount.toStringAsFixed(2)}'),
          subtitle: Text(DateFormat.yMMMd().add_jm().format(deposit.createdAt)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('+${deposit.coinsEarned} coins'),
          ),
        );
      },
    );
  }
}
