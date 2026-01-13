import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';

class TransactionStorage {
  static const _key = 'saved_transactions';

  static Future<void> save(List<TransactionModel> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(transactions.map((e) => e.toMap()).toList());
    await prefs.setString(_key, data);
  }

  static Future<List<TransactionModel>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    final List decoded = jsonDecode(data);
    return decoded.map((e) => TransactionModel.fromMap(e)).toList();
  }
}
