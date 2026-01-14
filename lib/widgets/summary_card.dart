import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final double balance;

  const SummaryCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B88FF), Color(0xFF635AD9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF635AD9).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tổng số dư hiện có",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "STK: 123 456 789",
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
              Icon(
                Icons.contactless_outlined,
                color: Colors.white.withValues(alpha: 0.5),
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}