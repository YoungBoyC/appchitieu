import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/transaction_model.dart';
import '../../widgets/transaction_item.dart';
import '../../widgets/common_widgets.dart';

class ReportTab extends StatelessWidget {
  final List<TransactionModel> transactions;
  final double totalIncome;
  final double totalExpense;

  const ReportTab({
    super.key,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
  });

  List<PieChartSectionData> _getChartSections() {
    final expenseTransactions = transactions.where((t) => !t.isIncome).toList();
    if (expenseTransactions.isEmpty) {
      return [
        PieChartSectionData(
            color: Colors.grey.shade300, value: 1, title: '', radius: 50)
      ];
    }

    Map<String, double> categorySums = {};
    for (var t in expenseTransactions) {
      categorySums[t.category] = (categorySums[t.category] ?? 0) + t.amount;
    }

    final colors = [
      const Color(0xFF635AD9),
      Colors.redAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.purpleAccent
    ];
    int index = 0;

    return categorySums.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      final double percentage = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0;
      
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final expenseList = transactions.where((t) => !t.isIncome).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text("Báo cáo chi tiêu",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ]),
            child: PieChart(PieChartData(
              sections: _getChartSections(),
              centerSpaceRadius: 40,
              sectionsSpace: 4,
            )),
          ),
          
          const SizedBox(height: 30),
          const SectionHeader(title: "Phân bổ chi tiêu", actionText: ""),
          
          if (expenseList.isEmpty)
            const Center(
                child: Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text("Chưa có dữ liệu chi tiêu để phân tích"),
            ))
          else
            ...expenseList.map((t) => TransactionItem(transaction: t)),
            
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}