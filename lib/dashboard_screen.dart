import 'package:flutter/material.dart';
import 'package:econosmart/theme/app_colors.dart';
import 'package:econosmart/expense_service.dart';
import 'package:econosmart/floating_chatbot.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _expenseService = ExpenseService();
  Map<String, double> _monthlySummary = {};
  Map<String, double> _categorySummary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final summary = await _expenseService.getMonthlySummary(now);
    final categorySummary = await _expenseService.getCategorySummary(now);

    setState(() {
      _monthlySummary = summary;
      _categorySummary = categorySummary;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithChatbot(
      bottomNavIndex: 0,
      child: Scaffold(
        backgroundColor: AppColors.panelTeal,
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Total Income',
                              amount: _monthlySummary['totalIncome'] ?? 0.0,
                              color: Colors.green,
                              icon: Icons.trending_up,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Total Expenses',
                              amount: _monthlySummary['totalExpenses'] ?? 0.0,
                              color: Colors.red,
                              icon: Icons.trending_down,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SummaryCard(
                        title: 'Net Balance',
                        amount: _monthlySummary['balance'] ?? 0.0,
                        color: (_monthlySummary['balance'] ?? 0.0) >= 0
                            ? Colors.blue
                            : Colors.orange,
                        icon: Icons.account_balance,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 32),

                      // Charts Section
                      const Text(
                        'Expense Breakdown',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pie Chart
                      Container(
                        height: 200,
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
                        child: _categorySummary.isEmpty
                            ? const Center(
                                child: Text(
                                  'No expense data available',
                                  style: TextStyle(color: AppColors.textGrey),
                                ),
                              )
                            : PieChart(
                                PieChartData(
                                  sections: _buildPieChartSections(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Category List
                      const Text(
                        'Category Details',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ..._categorySummary.entries
                          .map((entry) => _CategoryDetailCard(
                                category: entry.key,
                                amount: entry.value,
                              )),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.green,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];

    final total =
        _categorySummary.values.fold<double>(0, (sum, value) => sum + value);

    return _categorySummary.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final colorIndex =
          _categorySummary.keys.toList().indexOf(entry.key) % colors.length;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[colorIndex],
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
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
      padding: const EdgeInsets.all(20),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'LKR ${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return fullWidth ? card : Expanded(child: card);
  }
}

class _CategoryDetailCard extends StatelessWidget {
  final String category;
  final double amount;

  const _CategoryDetailCard({
    required this.category,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(category),
              color: _getCategoryColor(category),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'LKR ${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
      default:
        return Icons.category;
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
      default:
        return AppColors.primaryTeal;
    }
  }
}
