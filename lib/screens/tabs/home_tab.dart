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
  final String langCode; // Đã thêm để nhận diện ngôn ngữ

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

    // Sắp xếp giao dịch theo thời gian tăng dần để vẽ biểu đồ
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
    // Biến hỗ trợ dịch thuật nhanh trong Widget
    final isVi = langCode == 'vi';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Widget SummaryCard (Lưu ý: Bạn có thể cần truyền langCode vào đây nếu bên trong nó có text)
          SummaryCard(balance: currentBalance),
          
          const SizedBox(height: 24),
          
          // Nút chức năng Nạp/Chuyển
          ActionButtons(onTopUp: onTopUp, onTransfer: onTransfer),
          
          const SizedBox(height: 32),
          
          // Biểu đồ xu hướng
          SectionHeader(
            title: isVi ? "Xu hướng số dư" : "Balance Trend", 
            actionText: isVi ? "Tháng này" : "This Month"
          ),
          _buildLineChartCard(context),
          
          const SizedBox(height: 32),
          
          // Danh sách giao dịch
          SectionHeader(
            title: isVi ? "Giao dịch gần đây" : "Recent Transactions", 
            actionText: isVi ? "Xem tất cả" : "See All"
          ),
          _buildTransactionList(isVi),
          
          const SizedBox(height: 100), // Khoảng trống cho FAB
        ],
      ),
    );
  }

  // --- BUILD BIỂU ĐỒ ---
  Widget _buildLineChartCard(BuildContext context) {
    final spots = _generateSpots();
    const primaryColor = Color(0xFF635AD9);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 200, 
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 12, right: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
              color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
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

  // --- BUILD DANH SÁCH GIAO DỊCH ---
  Widget _buildTransactionList(bool isVi) {
    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text(
                isVi ? "Chưa có giao dịch nào" : "No transactions yet",
                style: TextStyle(color: Colors.grey[500]),
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
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            // Gọi hàm xóa đã truyền từ HomeScreen
            onDelete(index);
            return false;
          },
          child: TransactionItem(transaction: tx),
        );
      },
    );
  }
}