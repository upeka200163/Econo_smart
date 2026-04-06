import 'package:econosmart/database_helper.dart';
import 'package:econosmart/expense_model.dart';
import 'notification_service.dart';

class ExpenseService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> addTransaction(ExpenseModel transaction) async {
    await _dbHelper.insertTransaction(transaction);

    // Check for budget overspending after adding expense
    if (!transaction.isIncome) {
      await _checkBudgetAlerts(transaction.date);
    }
  }

  Future<List<ExpenseModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? accountType,
    bool? isIncome,
  }) async {
    return await _dbHelper.getTransactions(
      startDate: startDate,
      endDate: endDate,
      category: category,
      accountType: accountType,
      isIncome: isIncome,
    );
  }

  Future<List<ExpenseModel>> getTodayTransactions() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return await getTransactions(startDate: start, endDate: end);
  }

  Future<List<ExpenseModel>> getMonthlyTransactions(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    return await getTransactions(startDate: start, endDate: end);
  }

  Future<void> updateTransaction(ExpenseModel transaction) async {
    await _dbHelper.updateTransaction(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _dbHelper.deleteTransaction(int.parse(id));
  }

  Future<Map<String, double>> getMonthlySummary(DateTime month) async {
    return await _dbHelper.getMonthlySummary(month);
  }

  Future<Map<String, double>> getOverallSummary() async {
    return await _dbHelper.getOverallSummary();
  }

  Future<Map<String, double>> getCategorySummary(DateTime month) async {
    return await _dbHelper.getCategorySummary(month);
  }

  // Budget methods
  Future<void> setMonthlyBudget(
      String category, double amount, DateTime month) async {
    final existing = await _dbHelper.getBudget(category, month);
    if (existing != null) {
      await _dbHelper.updateBudget(category, amount, month);
    } else {
      await _dbHelper.insertBudget(category, amount, month);
    }
  }

  Future<double?> getMonthlyBudget(String category, DateTime month) async {
    return await _dbHelper.getBudget(category, month);
  }

  Future<double> getTotalMonthlyBudget(DateTime month) async {
    final categories = ['Food', 'Travel', 'Bills', 'Shopping', 'Other'];
    double total = 0;
    for (final category in categories) {
      final budget = await getMonthlyBudget(category, month);
      if (budget != null) total += budget;
    }
    return total;
  }

  Future<bool> isOverBudget(DateTime month) async {
    final summary = await getMonthlySummary(month);
    final totalBudget = await getTotalMonthlyBudget(month);
    return summary['totalExpenses']! > totalBudget + 5000;
  }

  Future<void> _checkBudgetAlerts(DateTime date) async {
    final month = DateTime(date.year, date.month);
    final summary = await getMonthlySummary(month);
    final totalBudget = await getTotalMonthlyBudget(month);

    if (summary['totalExpenses']! > totalBudget) {
      final overAmount = summary['totalExpenses']! - totalBudget;
      await NotificationService().showOverspendingAlert(overAmount);
    }
  }
}
