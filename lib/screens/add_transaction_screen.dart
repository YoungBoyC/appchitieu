import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class AddTransactionScreen extends StatefulWidget {
  // Thêm tham số isIncomeInitial để nhận trạng thái từ HomeScreen
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

      if (enteredTitle.isEmpty || enteredAmount <= 0) return;

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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text("Thêm Giao Dịch"),
        centerTitle: true,
        backgroundColor: _isIncome ? Colors.green.shade700 : const Color(0xFF635AD9),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ]
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Tên khoản chi/thu",
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Số tiền",
                      prefixIcon: Icon(Icons.money),
                      suffixText: "₫",
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: ['Ăn uống', 'Di chuyển', 'Giải trí', 'Lương', 'Khác']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => _category = val!),
                    decoration: const InputDecoration(
                      labelText: "Danh mục",
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: SwitchListTile(
                title: const Text("Đây là thu nhập?", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_isIncome ? "Dòng tiền đi vào" : "Dòng tiền đi ra"),
                value: _isIncome,
                activeColor: Colors.green,
                onChanged: (val) => setState(() {
                  _isIncome = val;
                  // Gợi ý category nhanh khi switch
                  if (val && _category != 'Lương') _category = 'Lương';
                  if (!val && _category == 'Lương') _category = 'Ăn uống';
                }),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isIncome ? Colors.green.shade700 : const Color(0xFF635AD9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
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