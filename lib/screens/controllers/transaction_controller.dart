import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/transaction_model.dart';

class TransactionController {
  static const String storageKey = 'saved_transactions';

  // Lưu danh sách giao dịch
  static Future<void> save(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(transactions.map((e) => e.toMap()).toList());
    await prefs.setString(storageKey, data);
  }

  // Load danh sách giao dịch
  static Future<List<TransactionModel>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.map((e) => TransactionModel.fromMap(e)).toList();
  }

  // Tính tổng thu
  static double totalIncome(List<TransactionModel> list) =>
      list.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);

  // Tính tổng chi
  static double totalExpense(List<TransactionModel> list) =>
      list.where((t) => !t.isIncome).fold(0, (s, t) => s + t.amount);
}
