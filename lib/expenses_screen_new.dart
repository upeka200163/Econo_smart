import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:econosmart/theme/app_colors.dart';
import 'package:econosmart/expense_service.dart';
import 'package:econosmart/expense_model.dart';
import 'package:econosmart/add_expense_screen.dart';
import 'package:econosmart/expense_data_sheet_page.dart';
import 'package:econosmart/floating_chatbot.dart';

class ExpensesScreenNew extends StatefulWidget {
  const ExpensesScreenNew({super.key});

  @override
  State<ExpensesScreenNew> createState() => _ExpensesScreenNewState();
}

class _ExpensesScreenNewState extends State<ExpensesScreenNew> {
  final _expenseService = ExpenseService();
  int _selectedCategory = 0;
  int _selectedTab = 0; // 0=Today, 1=Monthly
  Map<String, double> _budgets = {};
  bool _isOverBudget = false;
  Map<String, double> _monthlySummary = {};
  Key _refreshKey = UniqueKey(); // Add refresh key for FutureBuilder

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': '📊'},
    {'label': 'Food', 'icon': '🍔'},
    {'label': 'Travel', 'icon': '✈️'},
    {'label': 'Bills', 'icon': '💡'},
    {'label': 'Shopping', 'icon': '🛍️'},
    {'label': 'Income', 'icon': '💰'},
  ];

  final List<String> _accountTypes = ['Cash', 'Bank', 'Investment'];

  String get _selectedCategoryLabel =>
      _categories[_selectedCategory]['label'] as String;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
    _loadMonthlyData();
  }

  Future<void> _loadBudgets() async {
    final now = DateTime.now();
    final Map<String, double> updatedBudgets = {};
    
    for (final category in _categories) {
      final label = category['label'] as String;
      if (label != 'All' && label != 'Income') {
        final budget = await _expenseService.getMonthlyBudget(label, now);
        updatedBudgets[label] = budget ?? 0.0;
      }
    }

    // Load the explicit 'Overall' budget used in the AppBar
    final overallBudget = await _expenseService.getMonthlyBudget('Overall', now);
    updatedBudgets['Overall'] = overallBudget ?? 0.0;

    setState(() {
      _budgets = updatedBudgets;
    });
  }

  Future<void> _loadMonthlyData() async {
    final now = DateTime.now();
    final summary = await _expenseService.getMonthlySummary(now);
    final overBudget = await _expenseService.isOverBudget(now);
    setState(() {
      _monthlySummary = summary;
      _isOverBudget = overBudget;
    });
  }

  void _refreshData() async {
    setState(() {
      _refreshKey = UniqueKey(); // Update refresh key to force FutureBuilder rebuild
    });
    await _loadMonthlyData();
    await _loadBudgets();
  }

  Future<void> _saveBudget(String category, double amount) async {
    final now = DateTime.now();
    await _expenseService.setMonthlyBudget(category, amount, now);
    await _loadBudgets();
    await _loadMonthlyData();
  }

  Future<void> _showBudgetDialog(String category) async {
    final controller = TextEditingController(
      text: _budgets[category]?.toStringAsFixed(2) ?? '0.00',
    );

    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set Monthly Budget for $category (LKR)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Budget Amount',
            prefixText: 'LKR ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text) ?? 0.0;
              if (value < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget cannot be negative')),
                );
                return;
              }
              Navigator.pop(ctx, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (amount != null) {
      await _saveBudget(category, amount);
    }
  }

  Future<void> _exportTransactionsCsv() async {
    try {
      final transactions = await _getFilteredTransactions();
      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions available to export.')),
        );
        return;
      }

      final rows = <List<String>>[
        [
          'Title',
          'Category',
          'Amount',
          'Type',
          'Account',
          'Date',
          'Time',
          'Description'
        ]
      ];
      for (final transaction in transactions) {
        rows.add([
          transaction.title,
          transaction.category,
          transaction.amount.toStringAsFixed(2),
          transaction.isIncome ? 'Income' : 'Expense',
          transaction.accountType,
          DateFormat('yyyy-MM-dd').format(transaction.date),
          transaction.time,
          transaction.description,
        ]);
      }

      final csv = rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transactions exported to ${file.path}'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<List<ExpenseModel>> _getFilteredTransactions() async {
    final now = DateTime.now();
    if (_selectedTab == 0) {
      // Today
      return await _expenseService.getTodayTransactions();
    } else {
      // Monthly
      return await _expenseService.getMonthlyTransactions(now);
    }
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'travel':
        return Icons.flight;
      case 'bills':
        return Icons.receipt;
      case 'shopping':
        return Icons.shopping_bag;
      case 'salary':
      case 'income':
        return Icons.account_balance_wallet;
      case 'business':
        return Icons.business;
      case 'investment return':
        return Icons.trending_up;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'travel':
        return Colors.blue;
      case 'bills':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'salary':
      case 'income':
        return AppColors.primaryTeal;
      case 'business':
        return Colors.green;
      case 'investment return':
        return Colors.teal;
      default:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithChatbot(
      bottomNavIndex: 2,
      child: Scaffold(
        backgroundColor: AppColors.panelTeal,
        body: SafeArea(
          child: Column(
            children: [
              // ── App Bar ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      'Smart Money Manager',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedTab == 1) ...[
                      IconButton(
                        icon: const Icon(Icons.account_balance_wallet,
                            color: AppColors.primaryTeal),
                        onPressed: () => _showBudgetDialog('Overall'),
                        tooltip: 'Set Overall Monthly Budget',
                      ),
                      if (_isOverBudget)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'OVER BUDGET!',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.download,
                          color: AppColors.primaryTeal),
                      onPressed: _exportTransactionsCsv,
                      tooltip: 'Export transactions',
                    ),
                    IconButton(
                      icon: const Icon(Icons.table_rows,
                          color: AppColors.primaryTeal),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ExpenseDataSheetPage()),
                        );
                      },
                      tooltip: 'View data sheet',
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.primaryTeal),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddExpenseScreen()),
                        ).then((_) => _refreshData());
                      },
                    ),
                  ],
                ),
              ),

              // ── Budget Alert ───────────────────────────────────────────
              if (_isOverBudget)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Warning: You have exceeded your budget by more than LKR 5000!',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Category Chips ─────────────────────────────────────────
              SizedBox(
                height: 46,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, i) {
                    final selected = _selectedCategory == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryTeal
                              : AppColors.inputBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryTeal
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          '${_categories[i]['icon']} ${_categories[i]['label']}',
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textDark,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ── Today / Monthly Toggle ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: ['TODAY\'S LOG', 'MONTHLY BUDGET']
                        .asMap()
                        .entries
                        .map((e) => Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedTab = e.key),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _selectedTab == e.key
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    e.value,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _selectedTab == e.key
                                          ? AppColors.primaryTeal
                                          : Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Transaction List ───────────────────────────────────────
              Expanded(
                child: FutureBuilder<List<ExpenseModel>>(
                  key: _refreshKey, // Add key to force refresh
                  future: _getFilteredTransactions(),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.white));
                    }

                    final transactions = snap.data ?? [];
                    final filteredTransactions = transactions.where((t) {
                      if (_selectedCategory == 0) return true; // 'All'
                      if (_selectedCategoryLabel == 'Income') return t.isIncome;
                      // Filter for specific expense categories
                      return !t.isIncome && 
                             t.category.toLowerCase() == _selectedCategoryLabel.toLowerCase();
                    }).toList();

                    if (_selectedTab == 1) {
                      // Monthly view with summary
                      return _buildMonthlyView(filteredTransactions);
                    }

                    return filteredTransactions.isEmpty
                        ? const Center(
                            child: Text(
                              'No transactions yet.\nTap + to add one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.textGrey, fontSize: 15),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredTransactions.length,
                            itemBuilder: (ctx, i) {
                              final transaction = filteredTransactions[i];
                              return _TransactionCard(
                                transaction: transaction,
                                icon: _getCategoryIcon(transaction.category),
                                iconColor:
                                    _getCategoryColor(transaction.category),
                                onDelete: () => _deleteTransaction(transaction),
                                onEdit: () => _editTransaction(transaction),
                              );
                            },
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

  Widget _buildMonthlyView(List<ExpenseModel> transactions) {
    final totalIncome = _monthlySummary['totalIncome'] ?? 0.0;
    final totalExpenses = _monthlySummary['totalExpenses'] ?? 0.0;
    final balance = _monthlySummary['balance'] ?? 0.0;

    return Column(
      children: [
        // Summary Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Income',
                  amount: totalIncome,
                  color: Colors.green,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  title: 'Expenses',
                  amount: totalExpenses,
                  color: Colors.red,
                  icon: Icons.trending_down,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _SummaryCard(
            title: 'Balance',
            amount: balance,
            color: balance >= 0 ? Colors.blue : Colors.orange,
            icon: Icons.account_balance,
            fullWidth: true,
          ),
        ),

        // Category Breakdown
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children:
                _categories.where((cat) => cat['label'] != 'All').map((cat) {
              final category = cat['label'] as String;
              final categoryTransactions = transactions
                  .where((t) => category == 'Income'
                      ? t.isIncome
                      : t.category == category)
                  .toList();
              final spent = categoryTransactions.fold<double>(
                  0, (sum, t) => sum + (t.isIncome ? 0 : t.amount));
              final earned = categoryTransactions.fold<double>(
                  0, (sum, t) => sum + (t.isIncome ? t.amount : 0));
              final budget = _budgets[category] ?? 0.0;

              return _CategoryBudgetCard(
                category: category,
                spent: spent,
                earned: earned,
                budget: budget,
                onSetBudget: () => _showBudgetDialog(category),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteTransaction(ExpenseModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _expenseService.deleteTransaction(transaction.id);
      _refreshData(); // Refresh all data including transaction list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
    }
  }

  Future<void> _editTransaction(ExpenseModel transaction) async {
    // For now, just show a message. In a full implementation, you'd navigate to edit screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Edit functionality would open edit screen')),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final bool fullWidth;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'LKR ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    return fullWidth ? card : Expanded(child: card);
  }
}

class _CategoryBudgetCard extends StatelessWidget {
  final String category;
  final double spent;
  final double earned;
  final double budget;
  final VoidCallback onSetBudget;

  const _CategoryBudgetCard({
    required this.category,
    required this.spent,
    required this.earned,
    required this.budget,
    required this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final remaining = budget - spent;
    final isOverBudget = spent > budget && budget > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                category,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (category != 'Income')
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onSetBudget,
                  color: AppColors.primaryTeal,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (category == 'Income') ...[
            Text(
              'Earned: LKR ${earned.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (budget > 0) ...[
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: LKR ${spent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  remaining >= 0
                      ? 'Left: LKR ${remaining.toStringAsFixed(2)}'
                      : 'Over: LKR ${remaining.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    color: remaining >= 0 ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Spent: LKR ${spent.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No budget set',
              style: TextStyle(
                color: AppColors.primaryTeal,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final ExpenseModel transaction;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TransactionCard({
    required this.transaction,
    required this.icon,
    required this.iconColor,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${transaction.category} • ${transaction.accountType} • ${transaction.time}',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 11,
                    ),
                  ),
                  if (transaction.description.isNotEmpty)
                    Text(
                      transaction.description,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.isIncome ? '+' : '-'}LKR ${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color:
                        transaction.isIncome ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('MMM dd').format(transaction.date),
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
