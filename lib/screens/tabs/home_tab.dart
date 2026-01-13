import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/transaction_model.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/action_buttons.dart';
import '../../widgets/transaction_item.dart';
import '../../widgets/common_widgets.dart';

class HomeTab extends StatelessWidget {
  final List<TransactionModel> transactions;
  final double currentBalance;
  final double monthlyBudget;   
  final double totalExpense;    
  final VoidCallback onTopUp;
  final VoidCallback onTransfer;
  final VoidCallback onSetBudget; 
  final Function(int) onDelete;

  const HomeTab({
    super.key,
    required this.transactions,
    required this.currentBalance,
    required this.monthlyBudget,   
    required this.totalExpense,     
    required this.onTopUp,
    required this.onTransfer,
    required this.onSetBudget,    
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          SummaryCard(balance: currentBalance),
          const SizedBox(height: 24),
          ActionButtons(onTopUp: onTopUp, onTransfer: onTransfer),
          const SizedBox(height: 32),
          const SectionHeader(title: "Xu hướng chi tiêu", actionText: "Tháng này"),
          _buildLineChartCard(),
          const SizedBox(height: 32),
          const SectionHeader(title: "Giao dịch gần đây", actionText: "Xem tất cả"),
          _buildTransactionList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLineChartCard() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: LineChart(LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [const FlSpot(0, 1), const FlSpot(1, 1.5), const FlSpot(5, 3)],
            isCurved: true,
            color: const Color(0xFF7B88FF),
            barWidth: 4,
            belowBarData: BarAreaData(show: true, color: const Color(0xFF7B88FF).withOpacity(0.1)),
          ),
        ],
      )),
    );
  }

  Widget _buildTransactionList() {
    if (transactions.isEmpty) return const Center(child: Text("Chưa có giao dịch nào"));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return Dismissible(
          key: Key(tx.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.redAccent,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            onDelete(index);
            return false;
          },
          child: TransactionItem(transaction: tx),
        );
      },
    );
  }
}