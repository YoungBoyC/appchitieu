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
  
  // Các hàm callback bắt buộc
  final VoidCallback onTopUp;
  final VoidCallback onTransfer;
  final VoidCallback onSetBudget;
  final Function(int) onDelete;
  
  final String langCode;

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
    required this.langCode, 
  });

  // --- LOGIC TÍNH TOÁN ĐIỂM BIẾN ĐỘNG SỐ DƯ ---
  List<FlSpot> _generateSpots() {
    if (transactions.isEmpty) {
      return [const FlSpot(0, 0)];
    }

    // Sắp xếp giao dịch theo thời gian tăng dần để vẽ biểu đồ chính xác
    List<TransactionModel> sortedTxs = List.from(transactions);
    sortedTxs.sort((a, b) => a.date.compareTo(b.date));

    List<FlSpot> spots = [];
    double runningBalance = 0; 

    // Điểm khởi đầu (Gốc 0)
    spots.add(const FlSpot(0, 0));

    for (int i = 0; i < sortedTxs.length; i++) {
      final tx = sortedTxs[i];
      if (tx.isIncome) {
        runningBalance += tx.amount;
      } else {
        runningBalance -= tx.amount;
      }
      // i + 1 để tránh trùng điểm khởi đầu
      spots.add(FlSpot((i + 1).toDouble(), runningBalance));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final isVi = langCode == 'vi';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Thẻ hiển thị tổng số dư
          SummaryCard(balance: currentBalance),
          
          const SizedBox(height: 24),
          
          // Các nút nạp tiền/chuyển tiền
          ActionButtons(onTopUp: onTopUp, onTransfer: onTransfer),
          
          const SizedBox(height: 32),
          
          SectionHeader(
            title: isVi ? "Xu hướng số dư" : "Balance Trend", 
            actionText: isVi ? "Tháng này" : "This Month"
          ),
          
          _buildLineChartCard(context),
          
          const SizedBox(height: 32),
          
          SectionHeader(
            title: isVi ? "Giao dịch gần đây" : "Recent Transactions", 
            actionText: isVi ? "Xem tất cả" : "See All"
          ),
          
          _buildTransactionList(isVi),
          
          // Khoảng đệm để không bị FloatingActionButton che khuất
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- BUILD BIỂU ĐỒ BIẾN ĐỘNG ---
  Widget _buildLineChartCard(BuildContext context) {
    final spots = _generateSpots();
    const primaryColor = Color(0xFF635AD9); 
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final axisTextColor = isDark 
          ? Colors.white.withValues(alpha: 0.9)
          : Colors.black87;

    return Container(
      height: 240, 
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 12, right: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
              color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                String text = '';
                final double absValue = value.abs();
                final String sign = value < 0 ? '-' : '';
                if (absValue >= 1000000) {
                  text = '$sign${(absValue / 1000000).toStringAsFixed(1)}M';
                } else if (absValue >= 1000) {
                  text = '$sign${(absValue / 1000).toInt()}k';
                } else {
                  text = '$sign${absValue.toInt()}';
                }
                  
                  return Text(
                    text,
                    style: TextStyle(color: axisTextColor, fontSize: 11, fontWeight: FontWeight.w600),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(color: axisTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              preventCurveOverShooting: true,
              color: const Color.fromARGB(255, 198, 198, 209),
              barWidth: 4, 
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: spots.length < 15, 
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: const Color.fromARGB(255, 99, 110, 212),
                  strokeWidth: 2,
                  strokeColor: const Color.fromARGB(255, 215, 214, 219),
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.3),
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

  // --- BUILD DANH SÁCH GIAO DỊCH ---
  Widget _buildTransactionList(bool isVi) {
    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey.withValues(alpha: 0.4)),
              const SizedBox(height: 10),
              Text(
                isVi ? "Chưa có giao dịch nào" : "No transactions yet",
                style: TextStyle(color: Colors.grey.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
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
            child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
          ),
          confirmDismiss: (direction) async {
            onDelete(index); 
            return false; 
          },
          child: TransactionItem(transaction: tx),
        );
      },
    );
  }
}