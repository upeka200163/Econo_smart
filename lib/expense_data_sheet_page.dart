import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:econosmart/theme/app_colors.dart';
import 'package:econosmart/expense_service.dart';
import 'package:econosmart/expense_model.dart';

class ExpenseDataSheetPage extends StatelessWidget {
  const ExpenseDataSheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Expense Data Sheet',
          style: TextStyle(color: AppColors.textDark),
        ),
        iconTheme: const IconThemeData(color: AppColors.primaryTeal),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: const [
                  Icon(Icons.receipt_long,
                      color: AppColors.primaryTeal, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'All expense records shown in a clean, printable data sheet format.',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ExpenseModel>>(
                future: ExpenseService().getTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryTeal));
                  }

                  final expenses = snapshot.data ?? [];
                  if (expenses.isEmpty) {
                    return const Center(
                      child: Text(
                        'No expense records available.',
                        style:
                            TextStyle(color: AppColors.textGrey, fontSize: 15),
                      ),
                    );
                  }

                  final totalAmount = expenses.fold<double>(
                      0,
                      (sum, expense) =>
                          sum +
                          (expense.isIncome
                              ? expense.amount
                              : -expense.amount));

                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Net Total',
                              style: TextStyle(
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                            Text(
                              'Rs.${totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: totalAmount >= 0
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          itemCount: expenses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.inputBg),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: expense.isIncome
                                          ? AppColors.primaryTeal
                                              .withOpacity(0.14)
                                          : AppColors.gold.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      expense.isIncome
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      color: expense.isIncome
                                          ? AppColors.primaryTeal
                                          : AppColors.gold,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          expense.title,
                                          style: const TextStyle(
                                            color: AppColors.textDark,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${expense.category} • ${DateFormat('MMM dd, yyyy').format(expense.date)}',
                                          style: const TextStyle(
                                              color: AppColors.textGrey,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${expense.isIncome ? '+' : '-'}Rs.${expense.amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: expense.isIncome
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        expense.time,
                                        style: const TextStyle(
                                            color: AppColors.textGrey,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
