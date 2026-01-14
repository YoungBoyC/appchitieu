import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class AddTransactionScreen extends StatefulWidget {
  final bool? isIncomeInitial;

  const AddTransactionScreen({super.key, this.isIncomeInitial});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'Ăn uống';
  late bool _isIncome;

  @override
  void initState() {
    super.initState();
    _isIncome = widget.isIncomeInitial ?? false;
    if (_isIncome) {
      _category = 'Lương';
    }
  }

  void _submitData() {
    final enteredTitle = _titleController.text;
    final enteredAmount = double.tryParse(_amountController.text) ?? 0;

    if (enteredTitle.isEmpty || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên và số tiền hợp lệ")),
      );
      return;
    }

    final newTx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: enteredTitle,
      amount: enteredAmount,
      category: _category,
      isIncome: _isIncome,
      date: DateTime.now(),
    );

    Navigator.pop(context, newTx);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _isIncome ? Colors.green.shade700 : const Color(0xFF635AD9);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Thêm Giao Dịch", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), 
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "Tên khoản chi/thu",
                      prefixIcon: Icon(Icons.edit_note, color: primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                    decoration: InputDecoration(
                      labelText: "Số tiền",
                      prefixIcon: Icon(Icons.payments, color: primaryColor),
                      suffixText: "₫",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _category, 
                    key: ValueKey(_isIncome), 
                    items: (_isIncome 
                            ? ['Lương', 'Thưởng', 'Tiền lãi', 'Khác'] 
                            : ['Ăn uống', 'Di chuyển', 'Giải trí', 'Mua sắm', 'Y tế', 'Khác'])
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                        
                    onChanged: (val) {
                      setState(() {
                        _category = val!;
                      });
                    },
                    
                    decoration: InputDecoration(
                      labelText: "Danh mục",
                      prefixIcon: Icon(Icons.grid_view_rounded, color: primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SwitchListTile(
                title: const Text("Đây là thu nhập?", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_isIncome ? "Số tiền sẽ cộng vào ví" : "Số tiền sẽ trừ khỏi ví"),
                value: _isIncome,
                activeThumbColor: Colors.white, 
                activeTrackColor: Colors.green.shade600,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade300, 
                
                onChanged: (val) => setState(() {
                  _isIncome = val;
                  _category = val ? 'Lương' : 'Ăn uống'; 
                }),
              ),
            ),
            const SizedBox(height: 30),
            
            // Nút Lưu
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 2,
                ),
                onPressed: _submitData,
                child: const Text(
                  "LƯU GIAO DỊCH",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}