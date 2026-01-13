import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onDelete; 

  const TransactionItem({
    super.key, 
    required this.transaction, 
    this.onDelete
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.isIncome ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            transaction.isIncome ? Icons.south_west : Icons.north_east,
            color: transaction.isIncome ? Colors.green : Colors.red,
            size: 18,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          transaction.category,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          (transaction.isIncome ? "+" : "-") +
              currencyFormat.format(transaction.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: transaction.isIncome ? Colors.green : Colors.black,
          ),
        ),
      ),
    );
  }
}