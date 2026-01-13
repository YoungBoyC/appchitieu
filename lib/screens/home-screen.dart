import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_model.dart';
import '../widgets/action_buttons.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_item.dart';
import './add_transaction_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TransactionModel> _transactions = [];
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  // --- LOGIC LƯU TRỮ DỮ LIỆU ---
  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      _transactions.map((t) => t.toMap()).toList(),
    );
    await prefs.setString('saved_transactions', encodedData);
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('saved_transactions');
    if (savedData != null) {
      final List<dynamic> decodedData = jsonDecode(savedData);
      setState(() {
        _transactions = decodedData
            .map((item) => TransactionModel.fromMap(item))
            .toList();
      });
    }
  }

  // --- LOGIC TÍNH TOÁN ---
  double get totalIncome =>
      _transactions.where((t) => t.isIncome).fold(0, (sum, t) => sum + t.amount);
  double get totalExpense =>
      _transactions.where((t) => !t.isIncome).fold(0, (sum, t) => sum + t.amount);
  double get currentBalance => totalIncome - totalExpense;

  List<PieChartSectionData> _getChartSections() {
    final expenseTransactions =
        _transactions.where((t) => !t.isIncome).toList();
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
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent
    ];
    int index = 0;

    return categorySums.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      final double percentage = (entry.value / totalExpense) * 100;
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

  // --- ĐIỀU HƯỚNG & XỬ LÝ GIAO DIỆN ---
  void _deleteTransaction(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa giao dịch?"),
        content: const Text("Bạn có chắc chắn muốn xóa giao dịch này không?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              setState(() => _transactions.removeAt(index));
              _saveTransactions();
              Navigator.pop(ctx);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToMobileAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (result != null && result is TransactionModel) {
      setState(() {
        _transactions.insert(0, result);
      });
      _saveTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _selectedIndex == 0 ? _buildAppBar() : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(),
          _buildWalletContent(),
          _buildReportContent(),
          _buildSettingsContent(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF635AD9),
        elevation: 4,
        onPressed: _navigateToMobileAdd,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  // --- CÁC TAB NỘI DUNG (CHÍNH) ---

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Sử dụng Widget đã tách
          SummaryCard(balance: currentBalance),
          const SizedBox(height: 24),
          // Sử dụng Widget đã tách
          ActionButtons(
            onTopUp: _showTopUpSheet,
            onTransfer: _showTransferSheet,
          ),
          const SizedBox(height: 32),
          _buildSectionHeader("Xu hướng chi tiêu", "Tháng này"),
          _buildLineChartCard(),
          const SizedBox(height: 32),
          _buildSectionHeader("Giao dịch gần đây", "Xem tất cả"),
          _buildTransactionList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildWalletContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 40),
        const Text("Ví của tôi",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text("Quản lý các nguồn tiền của bạn",
            style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 25),
        _buildTotalWalletSummary(),
        const SizedBox(height: 30),
        const Text("Tài khoản & Thẻ",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _walletCard(
          "Số dư ứng dụng",
          currencyFormat.format(currentBalance),
          Icons.account_balance_wallet,
          const Color(0xFF635AD9),
          subtitle: "Tài khoản mặc định",
          onTap: () => _showWalletDetails("Số dư ứng dụng", currentBalance),
        ),
        _walletCard("Ví tiền mặt", "500.000₫", Icons.payments, Colors.orange,
            subtitle: "Tiền trong túi"),
        _walletCard("Ngân hàng MB", "Liên kết ngay", Icons.account_balance,
            Colors.blue,
            isLinked: false),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _showAddWalletSheet(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text("Thêm nguồn tiền mới",
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text("Tiện ích tài chính",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildUtilityItem("Hạn mức", Icons.speed, Colors.redAccent),
            _buildUtilityItem("Tiết kiệm", Icons.savings, Colors.pinkAccent),
            _buildUtilityItem("Hóa đơn", Icons.receipt_long, Colors.teal),
          ],
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildReportContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text("Báo cáo chi tiêu",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: PieChart(PieChartData(
                sections: _getChartSections(),
                centerSpaceRadius: 40,
                sectionsSpace: 4)),
          ),
          const SizedBox(height: 30),
          _buildSectionHeader("Phân bổ chi tiêu", ""),
          if (_transactions.where((t) => !t.isIncome).isEmpty)
            const Center(child: Text("Chưa có dữ liệu chi tiêu để phân tích")),
          ..._transactions
              .where((t) => !t.isIncome)
              .map((t) => TransactionItem(transaction: t)) // Reuse Widget
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF635AD9),
            child: Icon(Icons.person, size: 50, color: Colors.white)),
        const SizedBox(height: 16),
        const Center(
            child: Text("Thành Đạt",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        const Center(
            child: Text("Gói thành viên thường",
                style: TextStyle(color: Colors.grey))),
        const SizedBox(height: 30),
        const Divider(),
        _settingTile(Icons.language, "Ngôn ngữ", "Tiếng Việt"),
        _settingTile(Icons.security, "Bảo mật", "PIN & Vân tay"),
        _settingTile(Icons.help_outline, "Hỗ trợ", ""),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text("Đăng xuất",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          onTap: () {},
        ),
      ],
    );
  }

  // --- HÀM BỔ TRỢ GIAO DIỆN ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const Padding(
        padding: EdgeInsets.only(left: 16),
        child: CircleAvatar(
            backgroundColor: Color(0xFF635AD9),
            child: Icon(Icons.person, color: Colors.white, size: 20)),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Chào người dùng !",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          Text("Thành Đạt",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.black))
      ],
    );
  }

  Widget _buildTotalWalletSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryColumn(
              "Tổng thu", currencyFormat.format(totalIncome), Colors.green),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _summaryColumn(
              "Tổng chi", currencyFormat.format(totalExpense), Colors.red),
        ],
      ),
    );
  }

  Widget _summaryColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildUtilityItem(String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLineChartCard() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: LineChart(LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 1),
              const FlSpot(1, 1.5),
              const FlSpot(2, 1.2),
              const FlSpot(3, 2.5),
              const FlSpot(4, 2),
              const FlSpot(5, 3)
            ],
            isCurved: true,
            color: const Color(0xFF7B88FF),
            barWidth: 4,
            belowBarData: BarAreaData(
                show: true, color: const Color(0xFF7B88FF).withOpacity(0.1)),
          ),
        ],
      )),
    );
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("Chưa có giao dịch nào")));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return Dismissible(
          key: Key(transaction.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.only(right: 20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.delete_forever, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            _deleteTransaction(index);
            return false;
          },
          // Sử dụng Widget đã tách
          child: TransactionItem(transaction: transaction),
        );
      },
    );
  }

  Widget _walletCard(String name, String balance, IconData icon, Color color,
      {String? subtitle, bool isLinked = true, VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle ?? (isLinked ? "Đã kết nối" : "Chưa kết nối"),
            style: TextStyle(
                fontSize: 12,
                color: isLinked ? Colors.green : Colors.grey)),
        trailing: Text(balance,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isLinked ? const Color(0xFF635AD9) : Colors.grey)),
      ),
    );
  }

  // --- HÀM XỬ LÝ BOTTOM SHEETS ---
  // (Giữ nguyên logic bottom sheets vì liên quan đến context và state)

  void _showTopUpSheet() {
    final TextEditingController amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nạp tiền vào ví",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                  hintText: "Nhập số tiền",
                  prefixText: "₫ ",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15))),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF635AD9),
                    padding: const EdgeInsets.all(15)),
                onPressed: () {
                  final double? amount =
                      double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    final newTx = TransactionModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: "Nạp tiền vào ví",
                      amount: amount,
                      date: DateTime.now(),
                      category: "Nạp tiền",
                      isIncome: true,
                    );
                    setState(() => _transactions.insert(0, newTx));
                    _saveTransactions();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Xác nhận nạp",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showTransferSheet() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController accountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Chuyển tiền",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: accountController,
                        decoration: InputDecoration(
                            hintText: "Số tài khoản",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15))))),
                const SizedBox(width: 10),
                IconButton.filled(
                    onPressed: () => _openQRScanner(accountController),
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                    style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF635AD9))),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    hintText: "Số tiền",
                    prefixText: "₫ ",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.all(15)),
                onPressed: () {
                  final double? amount =
                      double.tryParse(amountController.text);
                  if (amount != null &&
                      amount > 0 &&
                      amount <= currentBalance) {
                    final newTx = TransactionModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: "Đến STK: ${accountController.text}",
                      amount: amount,
                      date: DateTime.now(),
                      category: "Chuyển khoản",
                      isIncome: false,
                    );
                    setState(() => _transactions.insert(0, newTx));
                    _saveTransactions();
                    Navigator.pop(context);
                  }
                },
                child: const Text("Xác nhận chuyển",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openQRScanner(TextEditingController controller) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text("Quét mã QR")),
                  body: MobileScanner(onDetect: (capture) {
                    final barcode = capture.barcodes.first;
                    if (barcode.rawValue != null) {
                      controller.text = barcode.rawValue!;
                      Navigator.pop(context);
                    }
                  }),
                )));
  }

  void _showWalletDetails(String name, double balance) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(currencyFormat.format(balance),
              style: const TextStyle(
                  fontSize: 24,
                  color: Color(0xFF635AD9),
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text("Lịch sử biến động của ví này sẽ hiển thị ở đây."),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  void _showAddWalletSheet() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Tính năng liên kết ngân hàng đang phát triển!")));
  }

  Widget _settingTile(IconData icon, String title, String trailing) {
    return ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(trailing, style: const TextStyle(color: Colors.grey)));
  }

  Widget _buildSectionHeader(String title, String actionText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(actionText,
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}