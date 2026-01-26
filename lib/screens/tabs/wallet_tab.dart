import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart'; // BẮT BUỘC THÊM

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
  final bool isDarkMode;
  final String langCode;

  const WalletTab({
    super.key,
    required this.currentBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.onShowDetails,
    required this.isDarkMode,
    required this.langCode,
  });

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> with WidgetsBindingObserver {
  bool get isVi => widget.langCode == 'vi';

  NumberFormat get currencyFormat => isVi
      ? NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
      : NumberFormat.currency(locale: 'en_US', symbol: '\$');

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

  // Biến dùng để theo dõi trạng thái app khi deep link
  bool _isReturningFromBankApp = false;
  Map<String, dynamic>? _pendingBankData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Lắng nghe sự kiện khi người dùng quay lại app từ App Ngân hàng
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isReturningFromBankApp && _pendingBankData != null) {
      _isReturningFromBankApp = false;
      // Delay một chút để UI ổn định
      Future.delayed(const Duration(milliseconds: 500), () {
        _showUpdateBalanceDialog(_pendingBankData!);
      });
    }
  }

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
              pw.Text(isVi ? "BÁO CÁO TÀI CHÍNH CÁ NHÂN" : "PERSONAL FINANCE REPORT", style: pw.TextStyle(font: fontBold, fontSize: 24)),
              pw.SizedBox(height: 10),
              pw.Text("${isVi ? "Ngày xuất" : "Date"}: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}", style: pw.TextStyle(font: font)),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(isVi ? "1. Tổng quan" : "1. Overview", style: pw.TextStyle(font: fontBold, fontSize: 18)),
              pw.Text("${isVi ? "Tổng thu" : "Total Income"}: ${currencyFormat.format(widget.totalIncome)}", style: pw.TextStyle(font: font)),
              pw.Text("${isVi ? "Tổng chi" : "Total Expense"}: ${currencyFormat.format(widget.totalExpense)}", style: pw.TextStyle(font: font)),
              pw.Text("${isVi ? "Số dư hiện tại" : "Current Balance"}: ${currencyFormat.format(widget.currentBalance)}", style: pw.TextStyle(font: font)),
              pw.SizedBox(height: 20),
              pw.Text(isVi ? "2. Danh sách ví" : "2. Wallets", style: pw.TextStyle(font: fontBold, fontSize: 18)),
              ...wallets.map((w) => pw.Text("- ${w.name}: ${currencyFormat.format(w.balance)}", style: pw.TextStyle(font: font))),
              pw.SizedBox(height: 20),
              pw.Text(isVi ? "3. Mục tiêu tiết kiệm" : "3. Saving Goals", style: pw.TextStyle(font: fontBold, fontSize: 18)),
              ...savingGoals.map((g) => pw.Text("- ${g.name}: ${((g.current / g.target) * 100).toStringAsFixed(1)}% (${currencyFormat.format(g.current)})", style: pw.TextStyle(font: font))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // --- HÀM LIÊN KẾT NGÂN HÀNG (REAL DEEP LINK) ---
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
            Text(isVi ? "Thêm nguồn tiền" : "Add Source", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: Text(isVi ? "Nhập thủ công" : "Manual Input", style: TextStyle(color: textColor)),
              onTap: () { Navigator.pop(context); _showManualAddForm(); },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.purple),
              title: Text(isVi ? "Liên kết ngân hàng (Mở App)" : "Link Bank Account (Open App)", style: TextStyle(color: textColor)),
              subtitle: Text(isVi ? "Mở app ngân hàng để kiểm tra số dư" : "Open bank app to check balance", style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () { Navigator.pop(context); _showBankSelectionList(); },
            ),
          ],
        ),
      ),
    );
  }

  void _showBankSelectionList() {
    Color sheetBg = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    Color textColor = widget.isDarkMode ? Colors.white : Colors.black;
    
    // Cấu hình thông tin App Ngân hàng thực tế
    final List<Map<String, dynamic>> vnbanks = [
      {
        'name': 'Vietcombank', 
        'color': const Color(0xFF76B900), 
        'android_package': 'com.VCB.MobileBanking',
        'ios_scheme': 'vietcombankmobile://'
      },
      {
        'name': 'MB Bank', 
        'color': const Color(0xFF1832E5), 
        'android_package': 'com.mbmobile',
        'ios_scheme': 'mbbank://'
      },
      {
        'name': 'Techcombank', 
        'color': const Color(0xFFE51B23), 
        'android_package': 'vn.com.techcombank.bb.app', // TCB Mobile mới
        'ios_scheme': 'techcombankmobile://'
      },
      {
        'name': 'TPBank', 
        'color': const Color(0xFF8B008B), 
        'android_package': 'com.tpb.mobile',
        'ios_scheme': 'tpbankmobile://'
      },
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
            Text(isVi ? "Chọn ngân hàng đã cài đặt" : "Select Installed Bank", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 10),
            Text(isVi ? "Chúng tôi sẽ mở App Ngân hàng của bạn để bạn xem số dư." : "We will launch your Bank App for you to check balance.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: vnbanks.length,
                itemBuilder: (context, index) => ListTile(
                  leading: CircleAvatar(backgroundColor: vnbanks[index]['color'], child: const Icon(Icons.account_balance, color: Colors.white, size: 16)),
                  title: Text(vnbanks[index]['name'], style: TextStyle(color: textColor)),
                  trailing: const Icon(Icons.open_in_new, color: Colors.grey, size: 20),
                  onTap: () => _openBankAppAndSync(vnbanks[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBankAppAndSync(Map<String, dynamic> bankInfo) async {
    Navigator.pop(context); // Đóng modal chọn ngân hàng

    // Tạo Uri để mở app
    Uri? uri;
    if (Theme.of(context).platform == TargetPlatform.android) {
      // Android dùng intent scheme hoặc package name nhưng url_launcher hỗ trợ tốt nhất qua scheme hoặc market
      // Ở đây ta dùng logic mở package nếu có thể, hoặc tìm trên store
      // Tuy nhiên, đơn giản nhất là thử mở, nếu không thì báo lỗi.
      // Lưu ý: url_launcher trên Android cần cấu hình AndroidManifest.
      uri = Uri.parse("market://details?id=${bankInfo['android_package']}"); // Link dự phòng tới store
      
      // Để mở app trực tiếp trên Android cần intent cụ thể hoặc dùng package manager.
      // Cách đơn giản nhất mà không cần plugin phức tạp là dùng `LaunchMode.externalApplication` 
      // Nhưng để mở chính xác App, thường ta cần một Deep Link Scheme của App đó (vd: vcb://).
      // Vì Scheme thay đổi tùy ngân hàng và không public chính thức, ta sẽ dùng cơ chế 'Launch App' giả lập bằng cách nhắc user.
      // Nhưng để code "Expert", ta sẽ thử launch scheme nếu biết, hoặc launch store.
      
      // Cải tiến: Thử mở bằng Scheme Android (nếu có), ở đây dùng tạm store link nếu không có scheme chính xác.
      // Thực tế: Hầu hết bank app VN không public scheme chuẩn cho dev bên thứ 3.
      // Ta sẽ dùng Android Intent thông qua plugin 'external_app_launcher' là tốt nhất, nhưng ở đây dùng url_launcher:
    } else {
      // iOS dùng Scheme
      uri = Uri.parse(bankInfo['ios_scheme']);
    }

    bool canOpen = false;
    
    // Logic cho iOS (khá chuẩn xác)
    if (Theme.of(context).platform == TargetPlatform.iOS) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          canOpen = true;
        }
    } 
    // Logic cho Android (Mở Store page của App ngân hàng nếu không deep link được, hoặc dùng Intent class)
    else {
       // Trên Android, ta thử dùng phương pháp open package manager (cần plugin android_intent_plus cho tốt nhất).
       // Nhưng với url_launcher, ta có thể thử mở Google Play của App đó để người dùng nhấn "Open".
       uri = Uri.parse("https://play.google.com/store/apps/details?id=${bankInfo['android_package']}");
       if (await canLaunchUrl(uri)) {
         await launchUrl(uri, mode: LaunchMode.externalApplication);
         canOpen = true;
       }
    }

    if (canOpen) {
      // Đánh dấu là đang đi sang app khác
      _isReturningFromBankApp = true;
      _pendingBankData = bankInfo;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isVi ? "Đang mở ${bankInfo['name']}..." : "Opening ${bankInfo['name']}..."),
          duration: const Duration(seconds: 2),
        )
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isVi ? "Không tìm thấy ứng dụng ${bankInfo['name']} trên máy." : "App ${bankInfo['name']} not found."))
      );
    }
  }

  void _showUpdateBalanceDialog(Map<String, dynamic> bankInfo) {
    final balanceController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Row(
          children: [
            Icon(Icons.sync, color: bankInfo['color']),
            const SizedBox(width: 10),
            Text(isVi ? "Cập nhật số dư" : "Update Balance"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isVi 
              ? "Bạn vừa kiểm tra ${bankInfo['name']}. Vui lòng nhập số dư hiện tại để đồng bộ." 
              : "You checked ${bankInfo['name']}. Please enter current balance to sync.",
              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bankInfo['color']),
              decoration: InputDecoration(
                labelText: isVi ? "Số dư hiện tại" : "Current Balance",
                border: const OutlineInputBorder(),
                prefixText: isVi ? "₫ " : "\$ ",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _pendingBankData = null;
              Navigator.pop(context);
            },
            child: Text(isVi ? "Hủy" : "Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: bankInfo['color']),
            onPressed: () {
              final balance = double.tryParse(balanceController.text) ?? 0;
              setState(() {
                wallets.add(WalletModel(
                  id: DateTime.now().toString(),
                  name: bankInfo['name'],
                  balance: balance,
                  icon: Icons.account_balance,
                  color: bankInfo['color'],
                  isLinked: true,
                  type: 'bank'
                ));
              });
              _pendingBankData = null;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isVi ? "Đã liên kết ${bankInfo['name']} thành công!" : "Linked ${bankInfo['name']} successfully!"))
              );
            },
            child: Text(isVi ? "Xác nhận" : "Confirm", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showManualAddForm() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(isVi ? "Thêm ví thủ công" : "Add Wallet Manually"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: isVi ? "Tên ví" : "Wallet Name")),
            TextField(controller: balanceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isVi ? "Số dư" : "Balance")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isVi ? "Hủy" : "Cancel")),
          ElevatedButton(onPressed: () {
            setState(() {
              wallets.add(WalletModel(id: DateTime.now().toString(), name: nameController.text, balance: double.tryParse(balanceController.text) ?? 0, icon: Icons.wallet, color: Colors.grey, type: 'manual'));
            });
            Navigator.pop(context);
          }, child: Text(isVi ? "Thêm" : "Add")),
        ],
      ),
    );
  }

  // --- CÁC HÀM LOGIC THÊM ---

  void _showAddSavingGoal(StateSetter setModalState) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(isVi ? "Mục tiêu mới" : "New Goal"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: isVi ? "Tên mục tiêu" : "Goal Name")),
            TextField(controller: targetController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isVi ? "Số tiền cần" : "Target Amount")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isVi ? "Hủy" : "Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && targetController.text.isNotEmpty) {
                setState(() {
                  savingGoals.add(SavingGoal(id: DateTime.now().toString(), name: nameController.text, target: double.parse(targetController.text), current: 0, color: Colors.blueAccent));
                });
                setModalState(() {}); 
                Navigator.pop(context);
              }
            },
            child: Text(isVi ? "Thêm" : "Add"),
          )
        ],
      ),
    );
  }

  void _showAddBill(StateSetter setModalState) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(isVi ? "Hóa đơn mới" : "New Bill"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: isVi ? "Tên hóa đơn" : "Bill Name")),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isVi ? "Số tiền" : "Amount")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isVi ? "Hủy" : "Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                setState(() {
                  bills.add(BillItem(id: DateTime.now().toString(), name: nameController.text, amount: double.parse(amountController.text), dueDate: DateTime.now().add(const Duration(days: 7))));
                });
                setModalState(() {}); 
                Navigator.pop(context);
              }
            },
            child: Text(isVi ? "Thêm" : "Add"),
          )
        ],
      ),
    );
  }

  // --- CÁC MODAL HIỂN THỊ DANH SÁCH ---

  void _showSavingGoalsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
                  Text(isVi ? "Tiết kiệm" : "Saving Goals", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
                  IconButton(onPressed: () => _showAddSavingGoal(setModalState), icon: const Icon(Icons.add_circle, color: Color(0xFF635AD9))),
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
                      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                      onDismissed: (direction) {
                        setState(() => savingGoals.removeAt(index));
                        setModalState(() {}); 
                      },
                      child: ListTile(
                        title: Text(goal.name, style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            LinearProgressIndicator(value: progress, color: goal.color, backgroundColor: Colors.grey.shade200),
                            Text("${currencyFormat.format(goal.current)} / ${currencyFormat.format(goal.target)}"),
                          ],
                        ),
                        trailing: Text("${(progress * 100).toStringAsFixed(0)}%"),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
                  Text(isVi ? "Hóa đơn sắp tới" : "Upcoming Bills", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
                  IconButton(onPressed: () => _showAddBill(setModalState), icon: const Icon(Icons.add_circle, color: Colors.teal)),
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
                      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                      onDismissed: (direction) {
                        setState(() => bills.removeAt(index));
                        setModalState(() {});
                      },
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long, color: Colors.teal),
                        title: Text(bill.name, style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
                        subtitle: Text("Hạn: ${DateFormat('dd/MM/yyyy').format(bill.dueDate)}"),
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

  void _showEditLimit() {
    final limitController = TextEditingController(text: monthlyLimit.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(isVi ? "Thiết lập hạn mức" : "Set Spending Limit"),
        content: TextField(controller: limitController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isVi ? "Hạn mức tháng này" : "Monthly Limit")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isVi ? "Hủy" : "Cancel")),
          ElevatedButton(onPressed: () {
            setState(() { monthlyLimit = double.tryParse(limitController.text) ?? monthlyLimit; });
            Navigator.pop(context);
          }, child: Text(isVi ? "Cập nhật" : "Update")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double realTotalBalance = wallets.fold(0, (sum, item) => sum + item.balance);
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final Color subTextColor = widget.isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 40),
          Text(isVi ? "Ví của tôi" : "My Wallets", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 30),
          _buildTotalWalletSummary(cardColor, textColor, subTextColor),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isVi ? "Tài khoản & Thẻ" : "Accounts & Cards", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              Text("${isVi ? "Tổng" : "Total"}: ${currencyFormat.format(realTotalBalance)}", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          ...wallets.map((wallet) => _walletCard(wallet, cardColor, textColor)),
          const SizedBox(height: 10),
          _buildAddButton(subTextColor),
          const SizedBox(height: 30),
          Text(isVi ? "Tiện ích tài chính" : "Financial Utilities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              UtilityItem(
                label: isVi ? "Hạn mức" : "Limit",
                icon: Icons.speed,
                color: Colors.redAccent,
                labelColor: textColor,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: cardColor,
                      title: Text(isVi ? "Hạn mức chi tiêu" : "Spending Limit", style: TextStyle(color: textColor)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("${isVi ? "Hạn mức" : "Limit"}: ${currencyFormat.format(monthlyLimit)}", style: TextStyle(color: textColor)),
                          Text("${isVi ? "Đã tiêu" : "Spent"}: ${currencyFormat.format(widget.totalExpense)}", style: TextStyle(color: textColor)),
                          const SizedBox(height: 10),
                          Text(isVi ? "Bạn đã chi tiêu ${((widget.totalExpense / monthlyLimit) * 100).toStringAsFixed(1)}% hạn mức." : "Spent ${((widget.totalExpense / monthlyLimit) * 100).toStringAsFixed(1)}% limit.", style: TextStyle(color: subTextColor, fontSize: 12)),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: _showEditLimit, child: Text(isVi ? "Chỉnh sửa" : "Edit")),
                        TextButton(onPressed: () => Navigator.pop(context), child: Text(isVi ? "Đóng" : "Close")),
                      ],
                    )
                  );
                }
              ),
              UtilityItem(label: isVi ? "Tiết kiệm" : "Savings", icon: Icons.savings, color: Colors.pinkAccent, labelColor: textColor, onTap: _showSavingGoalsList),
              UtilityItem(label: isVi ? "Hóa đơn" : "Bills", icon: Icons.receipt_long, color: Colors.teal, labelColor: textColor, onTap: _showBillsList),
              UtilityItem(label: isVi ? "Báo cáo" : "Reports", icon: Icons.picture_as_pdf, color: Colors.indigo, labelColor: textColor, onTap: _exportToPDF),
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
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryColumn(isVi ? "Tổng thu" : "Total Income", currencyFormat.format(widget.totalIncome), Colors.green, Icons.arrow_upward, subTextColor),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _summaryColumn(isVi ? "Tổng chi" : "Total Expense", currencyFormat.format(widget.totalExpense), Colors.red, Icons.arrow_downward, subTextColor),
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
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: wallet.color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(wallet.icon, color: wallet.color)),
        title: Text(wallet.name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        subtitle: Text(currencyFormat.format(wallet.balance)),
        trailing: wallet.isLinked ? const Icon(Icons.check_circle, color: Colors.green, size: 18) : Icon(Icons.chevron_right, color: textColor),
      ),
    );
  }

  Widget _buildAddButton(Color subTextColor) {
    return OutlinedButton(
      onPressed: _showAddWalletFlow,
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: BorderSide(color: subTextColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      child: Text(isVi ? "+ Thêm nguồn tiền mới" : "+ Add new source", style: TextStyle(color: subTextColor)),
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