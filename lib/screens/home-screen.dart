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
  
  // --- QUẢN LÝ TRẠNG THÁI HỆ THỐNG ---
  bool _isDarkMode = false; 
  bool _isNotificationOn = true; 
  String _langCode = 'vi'; 
  
  double _monthlyBudget = 0.0; 
  
  NumberFormat get currencyFormat => _langCode == 'vi' 
      ? NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
      : NumberFormat.currency(locale: 'en_US', symbol: '\$');

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
      setState(() {
        _transactions = decodedData
            .map((item) => TransactionModel.fromMap(item))
            .toList();
      });
    }

    setState(() {
      _monthlyBudget = prefs.getDouble('monthly_budget') ?? 5000000.0;
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
      _isNotificationOn = prefs.getBool('is_notification_on') ?? true;
      _langCode = prefs.getString('lang_code') ?? 'vi'; 
    });
  }

  // --- HÀM XỬ LÝ THAY ĐỔI CÀI ĐẶT ---
  Future<void> _updateBudget(double newBudget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', newBudget);
    if (mounted) setState(() => _monthlyBudget = newBudget);
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = value);
    await prefs.setBool('is_dark_mode', value);
  }

  Future<void> _changeLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _langCode = code;
    });
    await prefs.setString('lang_code', code);
  }

  Future<void> _toggleNotification() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isNotificationOn = !_isNotificationOn);
    await prefs.setBool('is_notification_on', _isNotificationOn);

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isNotificationOn 
              ? (_langCode == 'vi' ? "Đã BẬT thông báo" : "Notifications ON") 
              : (_langCode == 'vi' ? "Đã TẮT thông báo" : "Notifications OFF"),
          ),
          backgroundColor: _isNotificationOn ? Colors.green : Colors.red,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
      setState(() => _transactions.insert(0, result));
      _saveTransactions();
    }
  }

  // --- UI MODALS ---
  void _showBudgetDialog() {
    final controller = TextEditingController(text: _monthlyBudget.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(_langCode == 'vi' ? "Thiết lập hạn mức" : "Set Monthly Budget", 
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            suffixText: _langCode == 'vi' ? "₫" : "\$", 
            hintText: "5,000,000",
            hintStyle: TextStyle(color: _isDarkMode ? Colors.grey : null)
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_langCode == 'vi' ? "Hủy" : "Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF635AD9), foregroundColor: Colors.white),
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) _updateBudget(val);
              Navigator.pop(ctx);
            },
            child: Text(_langCode == 'vi' ? "Lưu" : "Save"),
          )
        ],
      ),
    );
  }

  void _pickMonth() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_langCode == 'vi' ? "Chọn thời gian" : "Select Month", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black)),
              const Divider(),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  itemCount: 12,
                  itemBuilder: (ctx, index) {
                    final month = index + 1;
                    final isSelected = _selectedMonth.month == month;
                    return ListTile(
                      title: Text("${_langCode == 'vi' ? 'Tháng' : 'Month'} $month, ${_selectedMonth.year}",
                        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF635AD9)) : null,
                      onTap: () {
                        setState(() => _selectedMonth = DateTime(_selectedMonth.year, month));
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

  PreferredSizeWidget _buildAppBar() {
    final Color textColor = _isDarkMode ? Colors.white : Colors.black;
    final Color subTextColor = _isDarkMode ? Colors.grey[400]! : Colors.grey;

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
        children: [
          Text(_langCode == 'vi' ? "Chào người dùng !" : "Hello User !", style: TextStyle(color: subTextColor, fontSize: 12)),
          const Text("", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: _pickMonth,
          icon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF635AD9)),
          label: Text("${_langCode == 'vi' ? 'T' : 'M'}${_selectedMonth.month}/${_selectedMonth.year}",
            style: const TextStyle(color: Color(0xFF635AD9), fontWeight: FontWeight.bold)),
        ),
        IconButton(
          onPressed: _toggleNotification, 
          icon: Icon(
            _isNotificationOn ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, 
            color: _isNotificationOn ? const Color(0xFF635AD9) : textColor
          )
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _deleteTransaction(int indexInFiltered) {
    final idToDelete = _filteredTransactions[indexInFiltered].id;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(_langCode == 'vi' ? "Xóa giao dịch?" : "Delete Transaction?", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
        content: Text(_langCode == 'vi' ? "Bạn có chắc muốn xóa không?" : "Are you sure you want to delete?", style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_langCode == 'vi' ? "Hủy" : "Cancel")),
          TextButton(
            onPressed: () {
              setState(() => _transactions.removeWhere((t) => t.id == idToDelete));
              _saveTransactions();
              Navigator.pop(ctx);
            },
            child: Text(_langCode == 'vi' ? "Xóa" : "Delete", style: const TextStyle(color: Colors.red)),
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
      backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_langCode == 'vi' ? "Nạp tiền vào ví" : "Top Up Wallet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: _langCode == 'vi' ? "Nhập số tiền" : "Enter amount", 
                hintStyle: TextStyle(color: _isDarkMode ? Colors.grey : null),
                prefixText: _langCode == 'vi' ? "₫ " : "\$ ",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
              ),
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
                      title: _langCode == 'vi' ? "Nạp tiền vào ví" : "Wallet Top Up",
                      amount: amount,
                      date: DateTime.now(),
                      category: _langCode == 'vi' ? "Nạp tiền" : "Top Up",
                      isIncome: true,
                    );
                    setState(() => _transactions.insert(0, newTx));
                    _saveTransactions();
                    Navigator.pop(context);
                  }
                },
                child: Text(_langCode == 'vi' ? "Xác nhận nạp" : "Confirm", style: const TextStyle(color: Colors.white)),
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
      backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_langCode == 'vi' ? "Chuyển tiền" : "Transfer Money", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: accountController,
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: _langCode == 'vi' ? "Số tài khoản" : "Account Number",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
                    ),
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
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: _langCode == 'vi' ? "Số tiền" : "Amount",
                prefixText: _langCode == 'vi' ? "₫ " : "\$ ",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDarkMode ? Colors.white : Colors.black, 
                  padding: const EdgeInsets.all(15)
                ),
                onPressed: () {
                  final double? amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0 && amount <= currentBalance) {
                    final newTx = TransactionModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: "STK: ${accountController.text}",
                      amount: amount,
                      date: DateTime.now(),
                      category: _langCode == 'vi' ? "Chuyển khoản" : "Transfer",
                      isIncome: false,
                    );
                    setState(() => _transactions.insert(0, newTx));
                    _saveTransactions();
                    Navigator.pop(context);
                  }
                },
                child: Text(_langCode == 'vi' ? "Xác nhận chuyển" : "Confirm Transfer", style: TextStyle(color: _isDarkMode ? Colors.black : Colors.white)),
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
          appBar: AppBar(title: Text(_langCode == 'vi' ? "Quét mã QR" : "QR Scanner")),
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
      backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black)),
            const SizedBox(height: 10),
            Text(currencyFormat.format(balance),
              style: const TextStyle(fontSize: 24, color: Color(0xFF635AD9), fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text(_langCode == 'vi' ? "Lịch sử biến động sẽ hiển thị ở đây." : "Transaction history will appear here.", 
              style: TextStyle(color: _isDarkMode ? Colors.grey : Colors.black87)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: (_selectedIndex == 0 || _selectedIndex == 2) ? _buildAppBar() : null,
      
      body: Theme(
        data: _isDarkMode 
            ? ThemeData.dark().copyWith(
                scaffoldBackgroundColor: const Color(0xFF121212),
                cardColor: const Color(0xFF1E1E1E),
                dividerColor: Colors.white12,
                dialogTheme: const DialogThemeData(
                  backgroundColor: Color(0xFF1E1E1E),
                ),
              )
            : ThemeData.light().copyWith(
                scaffoldBackgroundColor: const Color(0xFFF8F9FB),
                cardColor: Colors.white,
                dividerColor: Colors.grey[200],
                dialogTheme: const DialogThemeData(
                  backgroundColor: Colors.white,
                ),
              ),
        child: IndexedStack(
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
              langCode: _langCode, 
            ),
            WalletTab(
              currentBalance: currentBalance,
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              onShowDetails: _showWalletDetails,
              isDarkMode: _isDarkMode,
              langCode: _langCode,
            ),
            ReportTab(
              transactions: _filteredTransactions, 
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              langCode: _langCode, 
            ),
            SettingsTab(
              isDarkMode: _isDarkMode,
              onThemeChanged: _toggleTheme,
              currentLangCode: _langCode,     
              onLanguageChanged: _changeLanguage, 
            ),
          ],
        ),
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
        isDarkMode: _isDarkMode, 
      ),
    );
  }
}
