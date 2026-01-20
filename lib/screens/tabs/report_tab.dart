import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../widgets/common_widgets.dart';

class ReportTab extends StatefulWidget {
  final List<TransactionModel> transactions;
  final double totalIncome;
  final double totalExpense;
  final String langCode; 

  const ReportTab({
    super.key,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
    required this.langCode, 
  });

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  int touchedIndex = -1;
  String _selectedFilter = "Tháng này";

  final List<Color> _categoryColors = [
    const Color(0xFF635AD9),
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFFFFD93D),
    const Color(0xFF1A535C),
    const Color(0xFFFF9F1C),
    const Color(0xFF2EC4B6),
    const Color(0xFFE71D36),
  ];

  List<TransactionModel> get _filteredByTime {
    final now = DateTime.now();
    return widget.transactions.where((t) {
      if (_selectedFilter == "Hôm nay") {
        return t.date.day == now.day && t.date.month == now.month && t.date.year == now.year;
      } else if (_selectedFilter == "Tuần này") {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return t.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
      } else if (_selectedFilter == "Năm này") {
        return t.date.year == now.year;
      }
      return true; // Tháng này
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayTransactions = _filteredByTime.where((t) => !t.isIncome).toList();
    double currentPeriodExpense = displayTransactions.fold(0, (sum, t) => sum + t.amount);

    Map<String, double> categorySums = {};
    for (var t in displayTransactions) {
      categorySums[t.category] = (categorySums[t.category] ?? 0) + t.amount;
    }

    var sortedEntries = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text("Báo cáo chi tiêu",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          _buildFilterBar(),

          const SizedBox(height: 20),

          Container(
            height: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), // Đã sửa
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: sortedEntries.isEmpty
                ? _buildEmptyState()
                : Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                                      touchedIndex = -1;
                                      return;
                                    }
                                    touchedIndex = response.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sectionsSpace: 2,
                              centerSpaceRadius: 35,
                              sections: _showingSections(sortedEntries, currentPeriodExpense),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: sortedEntries.asMap().entries.map((entry) {
                            final color = _categoryColors[entry.key % _categoryColors.length];
                            final amountStr = NumberFormat.compactSimpleCurrency(locale: 'vi_VN').format(entry.value.value);
                            return _Indicator(
                              color: color,
                              text: entry.value.key,
                              amount: amountStr,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 30),
          SectionHeader(title: "Phân bổ chi tiết ($_selectedFilter)", actionText: ""),

          if (sortedEntries.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text("Không có dữ liệu chi tiêu"),
            ))
          else
            ...sortedEntries.asMap().entries.map((entry) {
              final color = _categoryColors[entry.key % _categoryColors.length];
              return _buildCategoryItem(entry.value.key, entry.value.value, currentPeriodExpense, color);
            }),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    List<String> filters = ["Hôm nay", "Tuần này", "Tháng này", "Năm này"];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedFilter == filters[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filters[index]),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF635AD9) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
              ),
              child: Center(
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _showingSections(List<MapEntry<String, double>> data, double total) {
    return List.generate(data.length, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;
      final entry = data[i];
      final percentage = (entry.value / total) * 100;

      return PieChartSectionData(
        color: _categoryColors[i % _categoryColors.length],
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });
  }

  Widget _buildCategoryItem(String category, double amount, double total, Color color) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1), // Đã sửa
            child: Icon(Icons.category, color: color, size: 20)
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: amount / total, 
                  color: color, 
                  backgroundColor: Colors.grey.shade100, 
                  minHeight: 4
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Text(currencyFormat.format(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("Chưa có dữ liệu", style: TextStyle(color: Colors.grey)));
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final String amount;

  const _Indicator({required this.color, required this.text, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 6),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 14), 
            child: Text(amount, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }
}