import 'package:flutter/material.dart';
import '../../widgets/common_widgets.dart';

class WalletTab extends StatelessWidget {
  final double currentBalance;
  final double totalIncome;
  final double totalExpense;
  final String formattedBalance;
  final Function(String, double) onShowDetails;
  final VoidCallback onAddWallet;

  const WalletTab({
    super.key,
    required this.currentBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.formattedBalance,
    required this.onShowDetails,
    required this.onAddWallet,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        const Text("Ví của tôi", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        _buildTotalWalletSummary(),
        const SizedBox(height: 30),
        const Text("Tài khoản & Thẻ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _walletCard("Số dư ứng dụng", formattedBalance, Icons.account_balance_wallet, const Color(0xFF635AD9),
            onTap: () => onShowDetails("Số dư ứng dụng", currentBalance)),
        _walletCard("Ví tiền mặt", "500.000₫", Icons.payments, Colors.orange),
        _walletCard("Ngân hàng MB", "Liên kết ngay", Icons.account_balance, Colors.blue, isLinked: false),
        const SizedBox(height: 10),
        _buildAddButton(),
        const SizedBox(height: 30),
        const Text("Tiện ích tài chính", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        const Row(
          children: [
            UtilityItem(label: "Hạn mức", icon: Icons.speed, color: Colors.redAccent),
            UtilityItem(label: "Tiết kiệm", icon: Icons.savings, color: Colors.pinkAccent),
            UtilityItem(label: "Hóa đơn", icon: Icons.receipt_long, color: Colors.teal),
          ],
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildTotalWalletSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryColumn("Tổng thu", "+ $totalIncome", Colors.green),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _summaryColumn("Tổng chi", "- $totalExpense", Colors.red),
        ],
      ),
    );
  }

  Widget _summaryColumn(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _walletCard(String name, String balance, IconData icon, Color color, {bool isLinked = true, VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(balance, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: onAddWallet,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(15)),
        child: const Center(child: Text("Thêm nguồn tiền mới")),
      ),
    );
  }
}