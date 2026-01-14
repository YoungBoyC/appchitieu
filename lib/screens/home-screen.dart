import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/transaction_model.dart';
import '../widgets/bottom_nav.dart';
import './tabs/home_tab.dart';
import './tabs/wallet_tab.dart';
import './tabs/report_tab.dart';
import './tabs/settings_tab.dart';
import './add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TransactionModel> _transactions = [];
  int _selectedIndex = 0;
  DateTime _selectedMonth = DateTime.now();
  
  double _monthlyBudget = 0.0; 
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- LOGIC LƯU TRỮ DỮ LIỆU ---
  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      _transactions.map((t) => t.toMap()).toList(),
    );
    await prefs.setString('saved_transactions', encodedData);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? savedData = prefs.getString('saved_transactions');
    if (savedData != null) {
      final List<dynamic> decodedData = jsonDecode(savedData);
      _transactions = decodedData
          .map((item) => TransactionModel.fromMap(item))
          .toList();
    }

    _monthlyBudget = prefs.getDouble('monthly_budget') ?? 5000000.0;
    
    if (mounted) setState(() {});
  }

  Future<void> _updateBudget(double newBudget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', newBudget);
    if (mounted) setState(() => _monthlyBudget = newBudget);
  }

  // --- LOGIC TÍNH TOÁN ---
  List<TransactionModel> get _filteredTransactions {
    return _transactions.where((t) {
      return t.date.month == _selectedMonth.month && 
             t.date.year == _selectedMonth.year;
    }).toList();
  }

  double get totalIncome =>
      _filteredTransactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
  
  double get totalExpense =>
      _filteredTransactions.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);

  double get currentBalance {
    double income = _transactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    double expense = _transactions.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    return income - expense;
  }

  // --- ĐIỀU HƯỚNG ---
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

  // --- UI HELPER: MODALS ---
  void _showBudgetDialog() {
    final controller = TextEditingController(text: _monthlyBudget.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Thiết lập hạn mức chi tiêu"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: "₫", hintText: "Ví dụ: 5000000"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF635AD9),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) _updateBudget(val);
              Navigator.pop(ctx);
            },
            child: const Text("Lưu"),
          )
        ],
      ),
    );
  }

  void _pickMonth() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Chọn thời gian", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  itemCount: 12,
                  itemBuilder: (ctx, index) {
                    final month = index + 1;
                    final isSelected = _selectedMonth.month == month;
                    return ListTile(
                      title: Text("Tháng $month, ${_selectedMonth.year}"),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF635AD9)) : null,
                      onTap: () {
                        setState(() {
                          _selectedMonth = DateTime(_selectedMonth.year, month);
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- APPBAR ---
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
          Text("Chào người dùng !", style: TextStyle(color: Colors.grey, fontSize: 12)),
          Text("Thành Đạt", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: _pickMonth,
          icon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF635AD9)),
          label: Text(
            "T${_selectedMonth.month}/${_selectedMonth.year}",
            style: const TextStyle(color: Color(0xFF635AD9), fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: Colors.black)),
        const SizedBox(width: 8),
      ],
    );
  }

  // --- CÁC HÀM XỬ LÝ (SHEETS & DELETE) ---
  void _deleteTransaction(int indexInFiltered) {
    final idToDelete = _filteredTransactions[indexInFiltered].id;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa giao dịch?"),
        content: const Text("Bạn có chắc chắn muốn xóa giao dịch này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              setState(() {
                _transactions.removeWhere((t) => t.id == idToDelete);
              });
              _saveTransactions();
              Navigator.pop(ctx);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showTopUpSheet() {
    final TextEditingController amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nạp tiền vào ví", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(hintText: "Nhập số tiền", prefixText: "₫ ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF635AD9), padding: const EdgeInsets.all(15)),
                onPressed: () {
                  final double? amount = double.tryParse(amountController.text);
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
                child: const Text("Xác nhận nạp", style: TextStyle(color: Colors.white)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Chuyển tiền", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: accountController,
                    decoration: InputDecoration(hintText: "Số tài khoản", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: () => _openQRScanner(accountController),
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF635AD9)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: "Số tiền", prefixText: "₫ ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.all(15)),
                onPressed: () {
                  final double? amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0 && amount <= currentBalance) {
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
                child: const Text("Xác nhận chuyển", style: TextStyle(color: Colors.white)),
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
        ),
      ),
    );
  }

  void _showWalletDetails(String name, double balance) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(currencyFormat.format(balance),
              style: const TextStyle(fontSize: 24, color: Color(0xFF635AD9), fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("Lịch sử biến động của ví này sẽ hiển thị ở đây."),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _selectedIndex == 0 || _selectedIndex == 2 ? _buildAppBar() : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeTab(
            transactions: _filteredTransactions,
            currentBalance: currentBalance,
            monthlyBudget: _monthlyBudget, 
            totalExpense: totalExpense,     
            onTopUp: _showTopUpSheet,
            onTransfer: _showTransferSheet,
            onDelete: _deleteTransaction,
            onSetBudget: _showBudgetDialog, 
          ),
          WalletTab(
            currentBalance: currentBalance,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            onShowDetails: _showWalletDetails,
          ),
          ReportTab(
            transactions: _filteredTransactions, 
            totalIncome: totalIncome,
            totalExpense: totalExpense
          ),
          const SettingsTab(),
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
}