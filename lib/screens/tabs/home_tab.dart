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

  // --- LOGIC TÍNH TOÁN ĐIỂM BIẾN ĐỘNG SỐ DƯ ---
  List<FlSpot> _generateSpots() {
    if (transactions.isEmpty) {
      return [const FlSpot(0, 0)];
    }

    List<TransactionModel> sortedTxs = List.from(transactions);
    sortedTxs.sort((a, b) => a.date.compareTo(b.date));

    List<FlSpot> spots = [];
    double runningBalance = 0; 

    for (int i = 0; i < sortedTxs.length; i++) {
      final tx = sortedTxs[i];
      if (tx.isIncome) {
        runningBalance += tx.amount;
      } else {
        runningBalance -= tx.amount;
      }
      spots.add(FlSpot(i.toDouble(), runningBalance));
    }
    return spots;
  }

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
          const SectionHeader(title: "Xu hướng số dư", actionText: "Tháng này"),
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
    final spots = _generateSpots();
    const primaryColor = Color(0xFF635AD9);

    return Container(
      height: 200, 
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 12, right: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true, 
              color: primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: spots.length < 10,
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.2),
                    primaryColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text("Chưa có giao dịch nào")),
      );
    }
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
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(15),
            ),
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