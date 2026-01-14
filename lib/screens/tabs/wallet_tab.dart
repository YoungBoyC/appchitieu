import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Model đơn giản cho Ví
class WalletModel {
  final String id;
  final String name;
  final double balance;
  final IconData icon;
  final Color color;
  final bool isLinked;
  final String type; // 'cash', 'bank', 'ewallet'

  WalletModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.icon,
    required this.color,
    this.isLinked = false,
    required this.type,
  });
}

class WalletTab extends StatefulWidget {
  final double currentBalance;
  final double totalIncome;
  final double totalExpense;
  final Function(String, double) onShowDetails;

  const WalletTab({
    super.key,
    required this.currentBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.onShowDetails,
  });

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  List<WalletModel> wallets = [
    WalletModel(id: '1', name: "Tiền mặt", balance: 500000, icon: Icons.money, color: Colors.green, type: 'cash'),
    WalletModel(id: '2', name: "MoMo", balance: 1250000, icon: Icons.account_balance_wallet, color: Colors.pink, type: 'ewallet', isLinked: true),
  ];

  final List<Map<String, dynamic>> supportedBanks = [
    {'name': 'MB Bank', 'color': Colors.blue, 'icon': Icons.account_balance},
    {'name': 'Vietcombank', 'color': Colors.green.shade800, 'icon': Icons.account_balance},
    {'name': 'Techcombank', 'color': Colors.red, 'icon': Icons.account_balance},
    {'name': 'TPBank', 'color': Colors.purple, 'icon': Icons.account_balance},
    {'name': 'ZaloPay', 'color': Colors.blueAccent, 'icon': Icons.qr_code},
  ];

  void _showAddWalletBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Chọn nguồn tiền muốn thêm", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: supportedBanks.length,
                itemBuilder: (context, index) {
                  final bank = supportedBanks[index];
                  return ListTile(
                    leading: CircleAvatar(
                      // SỬA LỖI: withOpacity -> withValues
                      backgroundColor: (bank['color'] as Color).withValues(alpha: 0.1),
                      child: Icon(bank['icon'], color: bank['color']),
                    ),
                    title: Text(bank['name']),
                    subtitle: const Text("Liên kết tài khoản"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      _showFakeLinkProcess(bank);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFakeLinkProcess(Map<String, dynamic> bank) {
    final TextEditingController balanceController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(bank['icon'], color: bank['color']),
            const SizedBox(width: 10),
            Text("Liên kết ${bank['name']}"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Vui lòng nhập số dư hiện tại để đồng bộ (Giả lập API):"),
            const SizedBox(height: 15),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Số dư thực tế",
                suffixText: "VNĐ",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF635AD9), foregroundColor: Colors.white),
            onPressed: () {
              if (balanceController.text.isNotEmpty) {
                setState(() {
                  wallets.add(WalletModel(
                    id: DateTime.now().toString(),
                    name: bank['name'],
                    balance: double.tryParse(balanceController.text) ?? 0,
                    icon: bank['icon'],
                    color: bank['color'],
                    type: 'bank',
                    isLinked: true,
                  ));
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Đã liên kết ${bank['name']} thành công!")),
                );
              }
            },
            child: const Text("Xác nhận & Liên kết"),
          ),
        ],
      ),
    );
  }

  void _showFeatureMessage(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Tính năng '$featureName' đang được cập nhật!"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF635AD9),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double realTotalBalance = wallets.fold(0, (sum, item) => sum + item.balance);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 40),
          const Text("Ví của tôi", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          
          _buildTotalWalletSummary(),
          
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tài khoản & Thẻ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Tổng: ${currencyFormat.format(realTotalBalance)}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          
          // SỬA LỖI Ở ĐÂY: Loại bỏ .toList() sau .map()
          ...wallets.map((wallet) => _walletCard(wallet)),
          
          const SizedBox(height: 10),
          _buildAddButton(),
          
          const SizedBox(height: 30),
          const Text("Tiện ích tài chính", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UtilityItem(label: "Hạn mức", icon: Icons.speed, color: Colors.redAccent, onTap: () => _showFeatureMessage("Cài đặt hạn mức")),
              UtilityItem(label: "Tiết kiệm", icon: Icons.savings, color: Colors.pinkAccent, onTap: () => _showFeatureMessage("Hũ tiết kiệm")),
              UtilityItem(label: "Hóa đơn", icon: Icons.receipt_long, color: Colors.teal, onTap: () => _showFeatureMessage("Quản lý hóa đơn")),
              UtilityItem(label: "Báo cáo", icon: Icons.bar_chart, color: Colors.indigo, onTap: () => _showFeatureMessage("Xuất báo cáo")),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTotalWalletSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        // SỬA LỖI: withOpacity -> withValues
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryColumn("Tổng thu", currencyFormat.format(widget.totalIncome), Colors.green, Icons.arrow_upward),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _summaryColumn("Tổng chi", currencyFormat.format(widget.totalExpense), Colors.red, Icons.arrow_downward),
        ],
      ),
    );
  }

  Widget _summaryColumn(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))]),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  Widget _walletCard(WalletModel wallet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => widget.onShowDetails(wallet.name, wallet.balance),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  // SỬA LỖI: withOpacity -> withValues
                  decoration: BoxDecoration(color: wallet.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(wallet.icon, color: wallet.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(wallet.balance),
                        style: TextStyle(
                          fontWeight: wallet.isLinked ? FontWeight.w600 : FontWeight.normal,
                          color: wallet.isLinked ? Colors.black87 : Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (wallet.isLinked)
                  const Tooltip(
                    message: "Đã liên kết",
                    child: Icon(Icons.check_circle, color: Colors.green, size: 18),
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: _showAddWalletBottomSheet,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text("Thêm nguồn tiền mới", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class UtilityItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const UtilityItem({super.key, required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}