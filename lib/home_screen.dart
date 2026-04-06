import 'package:flutter/material.dart';
import 'package:econosmart/theme/app_colors.dart';
import 'package:econosmart/auth_service.dart';
import 'package:econosmart/welcome_screen.dart';
import 'package:econosmart/economic_data_service.dart';
import 'package:econosmart/account_details_page.dart';
import 'package:econosmart/floating_chatbot.dart';
import 'package:econosmart/expense_service.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _expenseService = ExpenseService();
  Map<String, dynamic>? _userData;
  Map<String, double> _liveRates = {};
  int _selectedPeriod = 0; // 0=Weekly, 1=Monthly, 2=Yearly
  int _selectedTab = 0;
  double _totalBalance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;

  final List<Map<String, dynamic>> _fiscalData = [
    {
      'name': 'Red Sea Maritime',
      'value': 18.5,
      'color': const Color(0xFF4CAF82),
    },
    {
      'name': 'Semiconductor Shortage',
      'value': 7.2,
      'color': const Color(0xFF2196F3),
    },
    {
      'name': 'Oil Cuts (OPEC+)',
      'value': 24.1,
      'color': const Color(0xFFE57373),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadRates();
    _loadFinancialData();
  }

  Future<void> _loadUser() async {
    final data = await _authService.getUserData();
    if (mounted) setState(() => _userData = data);
  }

  Future<void> _loadRates() async {
    final rates = await EconomicDataService().getLiveRates();
    if (mounted) setState(() => _liveRates = rates);
  }

  Future<void> _loadFinancialData() async {
    final summary = await _expenseService.getOverallSummary();
    if (mounted) {
      setState(() {
        _totalBalance = summary['balance'] ?? 0.0;
        _totalIncome = summary['totalIncome'] ?? 0.0;
        _totalExpenses = summary['totalExpenses'] ?? 0.0;
      });
    }
  }

  void _showAccountMenu() {
    final email = _userData?['email'] as String? ?? '';
    final username = _userData?['username'] as String? ?? 'User';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF134545),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Account Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text('Username: $username',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text('Email: $email',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 22),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _showEditAccountDialog();
              },
              child: const SizedBox(
                width: double.infinity,
                child: Center(child: Text('Edit Account Details')),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _authService.signOut();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                );
              },
              child: const SizedBox(
                width: double.infinity,
                child: Center(
                    child:
                        Text('Logout', style: TextStyle(color: Colors.white))),
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditAccountDialog() async {
    final usernameController =
        TextEditingController(text: _userData?['username'] as String? ?? '');
    final passwordController = TextEditingController();
    var loading = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.primaryTeal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: const Text('Edit Account',
                  style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color(0xFF0F4A4A),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color(0xFF0F4A4A),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: loading
                      ? null
                      : () async {
                          final username = usernameController.text.trim();
                          final password = passwordController.text.trim();
                          if (username.isEmpty && password.isEmpty) {
                            return;
                          }
                          setState(() => loading = true);
                          String? error;
                          if (username.isNotEmpty) {
                            error = await _authService.updateUsername(username);
                          }
                          if (password.isNotEmpty && error == null) {
                            error = await _authService.updatePassword(password);
                          }
                          setState(() => loading = false);
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(error),
                                  backgroundColor: Colors.redAccent),
                            );
                            return;
                          }
                          await _loadUser();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Account updated successfully.')),
                          );
                        },
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = (_userData?['username'] as String?)?.trim();
    final profileUrl = _userData?['profileImageUrl'] as String?;
    final displayName =
        username != null && username.isNotEmpty ? username : 'User';

    return ScreenWithChatbot(
      bottomNavIndex: 0,
      child: Scaffold(
        backgroundColor: AppColors.panelTeal,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Econo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: 'Smart',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AccountDetailsPage(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          backgroundImage: profileUrl != null 
                              ? NetworkImage(profileUrl) 
                              : null,
                          child: profileUrl == null 
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $displayName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const Text(
                          'Good Morning',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Row(
                          children: const [
                            Icon(
                              Icons.location_on,
                              color: AppColors.gold,
                              size: 13,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'LIVE • COLOMBO',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Balance',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rs.${_totalBalance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: ['Weekly', 'Monthly', 'Yearly']
                          .asMap()
                          .entries
                          .map(
                            (e) => Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedPeriod = e.key),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedPeriod == e.key
                                        ? AppColors.primaryTeal
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  child: Text(
                                    e.value,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _selectedPeriod == e.key
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: _selectedPeriod == e.key
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _StatCard(
                        label: 'Income',
                        amount: 'Rs.${_totalIncome.toStringAsFixed(2)}',
                        icon: Icons.arrow_outward,
                        iconColor: AppColors.primaryTeal,
                      ),
                      const SizedBox(width: 14),
                      _StatCard(
                        label: 'Expense',
                        amount: 'Rs.${_totalExpenses.toStringAsFixed(2)}',
                        icon: Icons.south_east,
                        iconColor: Colors.blueAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Live Rate Cards Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _RateCard(
                        label: 'PETROL 92',
                        value:
                            'Rs.${_liveRates['OCTANE92']?.toStringAsFixed(0) ?? "398"}',
                        // Logic: Usually fuel price changes are infrequent but significant
                        change: '▲ Rs.53.00',
                        isPositive: null, // Neutral for fixed price items
                      ),
                      const SizedBox(width: 8),
                      _RateCard(
                        label: 'GOLD 24K',
                        value:
                            '${((_liveRates['GOLD'] ?? 388160) / 1000).toStringAsFixed(0)}K',
                        change: '▲ MARKET',
                        isPositive: false,
                      ),
                      const SizedBox(width: 8),
                      _RateCard(
                        label: 'USD/LKR',
                        value:
                            '${_liveRates['LKR']?.toStringAsFixed(2) ?? "314.80"}',
                        change: 'CBSL MID',
                        isPositive: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Rates update every 6 hours',
                    style: TextStyle(color: Colors.white30, fontSize: 10)),
                const SizedBox(height: 16),

                // Period Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: ['Weekly', 'Monthly', 'Yearly']
                          .asMap()
                          .entries
                          .map((e) => Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedPeriod = e.key),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _selectedPeriod == e.key
                                          ? const Color(0xFF5F7C81)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    child: Text(
                                      e.value,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _selectedPeriod == e.key
                                            ? Colors.white
                                            : Colors.white70,
                                        fontWeight: _selectedPeriod == e.key
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text(
                              'FISCAL VULNERABILITY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.trending_up,
                              color: AppColors.gold,
                              size: 16,
                            ),
                          ],
                        ),
                        const Text(
                          'Govt expense pressure by global crisis (%)',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 14),
                        ..._fiscalData.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '${item['value']}%',
                                      style: TextStyle(
                                        color: item['color'],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: item['value'] / 100,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.15,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      item['color'],
                                    ),
                                    minHeight: 5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Economy Fluctuations Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'ECONOMY FLUCTUATIONS (USD/LKR)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.show_chart,
                                color: AppColors.gold, size: 16),
                          ],
                        ),
                        const Text(
                          'Live variation over the last 30 days',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 120,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: const [
                                    FlSpot(0, 310.2),
                                    FlSpot(1, 312.5),
                                    FlSpot(2, 311.8),
                                    FlSpot(3, 314.8),
                                    FlSpot(4, 313.2),
                                    FlSpot(5, 315.5),
                                    FlSpot(6, 314.80),
                                  ],
                                  isCurved: true,
                                  color: AppColors.gold,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.gold.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  final String label;
  final String value;
  final String change;
  final bool? isPositive;

  const _RateCard({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            Text(change,
                style: TextStyle(
                    color: isPositive == null
                        ? Colors.white54
                        : (isPositive! ? Colors.greenAccent : Colors.redAccent),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
