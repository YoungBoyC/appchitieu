import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// --- MODELS ---

class WalletModel {
  final String id;
  final String name;
  final double balance;
  final IconData icon;
  final Color color;
  final bool isLinked;
  final String type;

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

class SavingGoal {
  final String id;
  final String name;
  final double target;
  final double current;
  final Color color;

  SavingGoal({required this.id, required this.name, required this.target, required this.current, required this.color});
}

class BillItem {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  bool isPaid;

  BillItem({required this.id, required this.name, required this.amount, required this.dueDate, this.isPaid = false});
}

// --- MAIN WIDGET ---

class WalletTab extends StatefulWidget {
  final double currentBalance;
  final double totalIncome;
  final double totalExpense;
  final Function(String, double) onShowDetails;
  final bool isDarkMode; // Nhận biến dark mode từ home

  const WalletTab({
    super.key,
    required this.currentBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.onShowDetails,
    required this.isDarkMode,
  });

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  List<WalletModel> wallets = [
    WalletModel(id: '1', name: "Tiền mặt", balance: 5000000, icon: Icons.money, color: Colors.green, type: 'cash'),
    WalletModel(id: '2', name: "MoMo", balance: 1250000, icon: Icons.account_balance_wallet, color: Colors.pink, type: 'ewallet', isLinked: true),
  ];

  double monthlyLimit = 10000000;

  List<SavingGoal> savingGoals = [
    SavingGoal(id: 's1', name: "Mua iPhone 16", target: 30000000, current: 12000000, color: Colors.blue),
  ];

  List<BillItem> bills = [
    BillItem(id: 'b1', name: "Tiền điện", amount: 1200000, dueDate: DateTime.now().add(const Duration(days: 5))),
  ];

  // --- HÀM XUẤT PDF ---
  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.beVietnamProRegular();
    final fontBold = await PdfGoogleFonts.beVietnamProBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("BÁO CÁO TÀI CHÍNH CÁ NHÂN", style: pw.TextStyle(font: fontBold, fontSize: 24)),
              pw.SizedBox(height: 10),
              pw.Text("Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}", style: pw.TextStyle(font: font)),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text("1. Tổng quan", style: pw.TextStyle(font: fontBold, fontSize: 18)),
              pw.Text("Tổng thu: ${currencyFormat.format(widget.totalIncome)}", style: pw.TextStyle(font: font)),
              pw.Text("Tổng chi: ${currencyFormat.format(widget.totalExpense)}", style: pw.TextStyle(font: font)),
              pw.Text("Số dư hiện tại: ${currencyFormat.format(widget.currentBalance)}", style: pw.TextStyle(font: font)),
              pw.SizedBox(height: 20),
              pw.Text("2. Danh sách ví", style: pw.TextStyle(font: fontBold, fontSize: 18)),
              ...wallets.map((w) => pw.Text("- ${w.name}: ${currencyFormat.format(w.balance)}", style: pw.TextStyle(font: font))),
              pw.SizedBox(height: 20),
              pw.Text("3. Mục tiêu tiết kiệm", style: pw.TextStyle(font: fontBold, fontSize: 18)),
              ...savingGoals.map((g) => pw.Text("- ${g.name}: ${((g.current / g.target) * 100).toStringAsFixed(1)}% (${currencyFormat.format(g.current)})", style: pw.TextStyle(font: font))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // --- TÍNH NĂNG LIÊN KẾT NGÂN HÀNG THỰC (SIMULATION) ---
  void _showAddWalletFlow() {
    Color sheetBg = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = widget.isDarkMode ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Thêm nguồn tiền", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: Text("Nhập thủ công", style: TextStyle(color: textColor)),
              subtitle: Text("Tự nhập tên và số dư", style: TextStyle(color: widget.isDarkMode ? Colors.grey : null)),
              onTap: () {
                Navigator.pop(context);
                _showManualAddForm();
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.purple),
              title: Text("Liên kết ngân hàng", style: TextStyle(color: textColor)),
              subtitle: Text("Kết nối an toàn qua ứng dụng ngân hàng", style: TextStyle(color: widget.isDarkMode ? Colors.grey : null)),
              onTap: () {
                Navigator.pop(context);
                _showBankSelectionList();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBankSelectionList() {
    Color sheetBg = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = widget.isDarkMode ? Colors.white : Colors.black;
    
    final List<Map<String, dynamic>> vnbanks = [
      {'name': 'Vietcombank', 'color': Colors.green},
      {'name': 'Techcombank', 'color': Colors.red},
      {'name': 'MB Bank', 'color': Colors.blue.shade900},
      {'name': 'TPBank', 'color': Colors.purple},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Chọn ngân hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: vnbanks.length,
                itemBuilder: (context, index) => ListTile(
                  leading: CircleAvatar(backgroundColor: vnbanks[index]['color'], child: const Icon(Icons.account_balance, color: Colors.white, size: 16)),
                  title: Text(vnbanks[index]['name'], style: TextStyle(color: textColor)),
                  trailing: Icon(Icons.chevron_right, color: textColor),
                  onTap: () => _simulateBankLinking(vnbanks[index]['name'], vnbanks[index]['color']),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateBankLinking(String bankName, Color bankColor) {
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text("Đang kết nối an toàn với $bankName...", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );

    // Giả lập kết nối API mất 2 giây
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context);
      setState(() {
        wallets.add(WalletModel(
          id: DateTime.now().toString(),
          name: bankName,
          balance: 15000000, // Giả lập số dư lấy được từ API
          icon: Icons.account_balance,
          color: bankColor,
          isLinked: true,
          type: 'bank',
        ));
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Liên kết thành công $bankName!")));
    });
  }

  void _showManualAddForm() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    Color dialogBg = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = widget.isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text("Thêm ví thủ công", style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: "Tên ví", labelStyle: TextStyle(color: textColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor)))),
            TextField(controller: balanceController, keyboardType: TextInputType.number, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: "Số dư", labelStyle: TextStyle(color: textColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  wallets.add(WalletModel(
                    id: DateTime.now().toString(),
                    name: nameController.text,
                    balance: double.tryParse(balanceController.text) ?? 0,
                    icon: Icons.wallet,
                    color: Colors.grey,
                    type: 'manual',
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text("Thêm")),
        ],
      ),
    );
  }

  // --- FORM THÊM MỤC TIÊU TIẾT KIỆM ---
  void _showAddSavingGoal() {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    Color dialogBg = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = widget.isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text("Mục tiêu mới", style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: "Tên mục tiêu", labelStyle: TextStyle(color: textColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor)))),
            TextField(controller: targetController, keyboardType: TextInputType.number, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: "Số tiền cần", labelStyle: TextStyle(color: textColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && targetController.text.isNotEmpty) {
                setState(() {
                  savingGoals.add(SavingGoal(
                    id: DateTime.now().toString(),
                    name: nameController.text,
                    target: double.parse(targetController.text),
                    current: 0,
                    color: Colors.blueAccent,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Thêm"),
          )
        ],
      ),
    );
  }

  // --- FORM THÊM HÓA ĐƠN ---
  void _showAddBill() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    Color dialogBg = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = widget.isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text("Hóa đơn mới", style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: "Tên hóa đơn", labelStyle: TextStyle(color: textColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor)))),
            TextField(controller: amountController, keyboardType: TextInputType.number, style: TextStyle(color: textColor), decoration: InputDecoration(labelText: "Số tiền", labelStyle: TextStyle(color: textColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                setState(() {
                  bills.add(BillItem(
                    id: DateTime.now().toString(),
                    name: nameController.text,
                    amount: double.parse(amountController.text),
                    dueDate: DateTime.now().add(const Duration(days: 7)),
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Thêm"),
          )
        ],
      ),
    );
  }

  // --- CÁC MODAL HIỂN THỊ DANH SÁCH + TÍNH NĂNG XÓA ---
  void _showSavingGoalsList() {
    Color sheetBg = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = widget.isDarkMode ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Tiết kiệm", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  IconButton(onPressed: _showAddSavingGoal, icon: const Icon(Icons.add_circle, color: Color(0xFF635AD9))),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: savingGoals.length,
                  itemBuilder: (context, index) {
                    final goal = savingGoals[index];
                    double progress = (goal.current / goal.target).clamp(0, 1);
                    return Dismissible(
                      key: Key(goal.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        setState(() => savingGoals.removeAt(index));
                        setModalState(() {});
                      },
                      child: ListTile(
                        title: Text(goal.name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            LinearProgressIndicator(value: progress, color: goal.color, backgroundColor: Colors.grey.shade200),
                            const SizedBox(height: 5),
                            Text("${currencyFormat.format(goal.current)} / ${currencyFormat.format(goal.target)}", style: TextStyle(color: widget.isDarkMode ? Colors.grey : null)),
                          ],
                        ),
                        trailing: Text("${(progress * 100).toStringAsFixed(0)}%", style: TextStyle(color: textColor)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBillsList() {
    Color sheetBg = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = widget.isDarkMode ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Hóa đơn sắp tới", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  IconButton(onPressed: _showAddBill, icon: const Icon(Icons.add_circle, color: Colors.teal)),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    return Dismissible(
                      key: Key(bill.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        setState(() => bills.removeAt(index));
                        setModalState(() {});
                      },
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long, color: Colors.teal),
                        title: Text(bill.name, style: TextStyle(color: textColor)),
                        subtitle: Text("Hạn: ${DateFormat('dd/MM/yyyy').format(bill.dueDate)}", style: TextStyle(color: widget.isDarkMode ? Colors.grey : null)),
                        trailing: Text(currencyFormat.format(bill.amount), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HÀM THIẾT LẬP HẠN MỨC ---
  void _showEditLimit() {
    final limitController = TextEditingController(text: monthlyLimit.toStringAsFixed(0));
    Color dialogBg = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = widget.isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text("Thiết lập hạn mức chi tiêu", style: TextStyle(color: textColor)),
        content: TextField(
          controller: limitController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(labelText: "Hạn mức tháng này (₫)", labelStyle: TextStyle(color: textColor), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                monthlyLimit = double.tryParse(limitController.text) ?? monthlyLimit;
              });
              Navigator.pop(context);
            },
            child: const Text("Cập nhật"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double realTotalBalance = wallets.fold(0, (sum, item) => sum + item.balance);

    // Bảng màu dựa trên Dark Mode
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final Color subTextColor = widget.isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    
    return Scaffold(
      // Màu nền được xử lý bởi Theme tại HomeScreen, nhưng đặt lại ở đây cho chắc chắn
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 40),
          Text("Ví của tôi", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 30),
          _buildTotalWalletSummary(cardColor, textColor, subTextColor),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Tài khoản & Thẻ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              Text("Tổng: ${currencyFormat.format(realTotalBalance)}", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          ...wallets.map((wallet) => _walletCard(wallet, cardColor, textColor)),
          const SizedBox(height: 10),
          _buildAddButton(subTextColor),
          const SizedBox(height: 30),
          Text("Tiện ích tài chính", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UtilityItem(
                  label: "Hạn mức",
                  icon: Icons.speed,
                  color: Colors.redAccent,
                  labelColor: textColor,
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              backgroundColor: cardColor,
                              title: Text("Hạn mức chi tiêu", style: TextStyle(color: textColor)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Hạn mức: ${currencyFormat.format(monthlyLimit)}", style: TextStyle(color: textColor)),
                                  Text("Đã tiêu: ${currencyFormat.format(widget.totalExpense)}", style: TextStyle(color: textColor)),
                                  const SizedBox(height: 10),
                                  Text("Bạn đã chi tiêu ${((widget.totalExpense / monthlyLimit) * 100).toStringAsFixed(1)}% hạn mức tháng này.", style: TextStyle(color: subTextColor)),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: _showEditLimit, child: const Text("Chỉnh sửa")),
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng")),
                              ],
                            ));
                  }),
              UtilityItem(label: "Tiết kiệm", icon: Icons.savings, color: Colors.pinkAccent, labelColor: textColor, onTap: _showSavingGoalsList),
              UtilityItem(label: "Hóa đơn", icon: Icons.receipt_long, color: Colors.teal, labelColor: textColor, onTap: _showBillsList),
              UtilityItem(label: "Báo cáo", icon: Icons.picture_as_pdf, color: Colors.indigo, labelColor: textColor, onTap: _exportToPDF),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTotalWalletSummary(Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryColumn("Tổng thu", currencyFormat.format(widget.totalIncome), Colors.green, Icons.arrow_upward, subTextColor),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _summaryColumn("Tổng chi", currencyFormat.format(widget.totalExpense), Colors.red, Icons.arrow_downward, subTextColor),
        ],
      ),
    );
  }

  Widget _summaryColumn(String label, String value, Color color, IconData icon, Color subTextColor) {
    return Column(
      children: [
        Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, color: subTextColor))]),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  Widget _walletCard(WalletModel wallet, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: () => widget.onShowDetails(wallet.name, wallet.balance),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: wallet.color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(wallet.icon, color: wallet.color),
        ),
        title: Text(wallet.name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        subtitle: Text(currencyFormat.format(wallet.balance), style: TextStyle(color: textColor.withOpacity(0.8))),
        trailing: wallet.isLinked ? const Icon(Icons.check_circle, color: Colors.green, size: 18) : Icon(Icons.chevron_right, color: textColor),
      ),
    );
  }

  Widget _buildAddButton(Color subTextColor) {
    return OutlinedButton(
      onPressed: _showAddWalletFlow,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15), 
        side: BorderSide(color: subTextColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
      ),
      child: Text("+ Thêm nguồn tiền mới", style: TextStyle(color: subTextColor)),
    );
  }
}

class UtilityItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color labelColor;
  final VoidCallback onTap;

  const UtilityItem({super.key, required this.label, required this.icon, required this.color, required this.labelColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: labelColor)),
      ],
    );
  }
}