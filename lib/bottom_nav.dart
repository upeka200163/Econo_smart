import 'package:flutter/material.dart';
import 'package:econosmart/theme/app_colors.dart';
import 'package:econosmart/home_screen.dart';
import 'package:econosmart/financial_report_screen.dart';
import 'package:econosmart/expenses_screen.dart';
import 'package:econosmart/global_crisis_screen.dart';
import 'package:econosmart/settings_screen.dart';

class BottomNavWidget extends StatelessWidget {
  final int currentIndex;
  const BottomNavWidget({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryTeal,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) {
          if (i == currentIndex) return;
          final screens = [
            const HomeScreen(),
            const FinancialReportScreen(),
            const ExpensesScreen(),
            const GlobalCrisisScreen(),
            const SettingsScreen(),
          ];
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => screens[i]),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Crisis'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
