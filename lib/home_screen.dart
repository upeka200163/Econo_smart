import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:econosmart/theme/app_colors.dart';
import 'package:econosmart/auth_service.dart';
import 'package:econosmart/welcome_screen.dart';
import 'package:econosmart/account_details_page.dart';
import 'package:econosmart/floating_chatbot.dart';
import 'package:econosmart/expense_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _expenseService = ExpenseService();
  Map<String, dynamic>? _userData;
  
  int _selectedPeriod = 0; // 0=Weekly, 1=Monthly, 2=Yearly
  double _totalBalance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;

  // Live Market Rates
  String _usdRate = 'Loading...';
  String _goldPrice = 'Loading...';
  String _oilPrice = 'Loading...';

  // World Bank Fiscal Data
  List<Map<String, dynamic>> _fiscalData = [];
  List<FlSpot> _inflationSpots = [];
  List<FlSpot> _gdpSpots = [];

  String _getApiKey(String keyName) {
    return dotenv.env[keyName] ?? '';
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadFinancialData();
    _fetchMarketRates();
    _fetchWorldBankData();
  }

  Future<void> _loadUser() async {
    final data = await _authService.getUserData();
    if (mounted) setState(() => _userData = data);
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

  Future<void> _fetchMarketRates() async {
    final exchangeRatesApiKey = _getApiKey('EXCHANGE_RATES_API_KEY');
    final goldApiKey = _getApiKey('GOLD_API_KEY');
    final alphaVantageApiKey = _getApiKey('ALPHA_VANTAGE_API_KEY');

    // 1. Fetch USD to LKR Exchange Rate (ExchangeRates-api)
    try {
      final exRes = await http.get(Uri.parse(
          'http://api.exchangeratesapi.io/v1/latest?access_key=$exchangeRatesApiKey&symbols=USD,LKR'));
      if (exRes.statusCode == 200) {
        final data = jsonDecode(exRes.body);
        // ExchangeRates free tier uses EUR base. Cross-calculate if needed: (LKR/EUR) / (USD/EUR)
        final lkr = data['rates']['LKR'];
        final usd = data['rates']['USD'];
        final usdToLkr = lkr / usd;
        if (mounted) setState(() => _usdRate = 'Rs.${usdToLkr.toStringAsFixed(2)}');
      }
    } catch (e) {
      if (mounted) setState(() => _usdRate = 'Error');
    }

    // 2. Fetch Gold Price (goldapi.io)
    try {
      final goldRes = await http.get(
        Uri.parse('https://www.goldapi.io/api/XAU/USD'),
        headers: {'x-access-token': goldApiKey},
      );
      if (goldRes.statusCode == 200) {
        final data = jsonDecode(goldRes.body);
        if (mounted) setState(() => _goldPrice = '\$${data['price'].toStringAsFixed(2)}');
      }
    } catch (e) {
      if (mounted) setState(() => _goldPrice = 'Error');
    }

    // 3. Fetch Brent Crude Oil Price (Alpha Vantage)
    try {
      final oilRes = await http.get(Uri.parse(
          'https://www.alphavantage.co/query?function=BRENT&interval=daily&apikey=$alphaVantageApiKey'));
      if (oilRes.statusCode == 200) {
        final data = jsonDecode(oilRes.body);
        final latestData = data['data'][0];
        if (mounted) setState(() => _oilPrice = '\$${latestData['value']}');
      }
    } catch (e) {
      if (mounted) setState(() => _oilPrice = 'Error');
    }
  }

  Future<void> _fetchWorldBankData() async {
    try {
      final infReq = http.get(Uri.parse('https://api.worldbank.org/v2/country/LK/indicator/FP.CPI.TOTL.ZG?format=json'));
      final gdpReq = http.get(Uri.parse('https://api.worldbank.org/v2/country/LK/indicator/NY.GDP.MKTP.KD.ZG?format=json'));
      final exReq = http.get(Uri.parse('https://api.worldbank.org/v2/country/LK/indicator/PA.NUS.FCRF?format=json'));

      final responses = await Future.wait([infReq, gdpReq, exReq]);

      List<FlSpot> parseSpots(String body) {
        final decoded = jsonDecode(body);
        if (decoded == null || decoded.length < 2) return [];
        final dataList = decoded[1] as List;
        List<FlSpot> spots = [];
        for (var item in dataList) {
          if (item['value'] != null && item['date'] != null) {
            spots.add(FlSpot(
              double.parse(item['date']),
              (item['value'] as num).toDouble(),
            ));
          }
        }
        spots.sort((a, b) => a.x.compareTo(b.x));
        return spots.length > 5 ? spots.sublist(spots.length - 5) : spots;
      }

      final infSpots = parseSpots(responses[0].body);
      final gdpSpots = parseSpots(responses[1].body);
      final exSpots = parseSpots(responses[2].body);

      double latestInf = infSpots.isNotEmpty ? infSpots.last.y : 0.0;
      double latestGdp = gdpSpots.isNotEmpty ? gdpSpots.last.y : 0.0;
      double latestEx = exSpots.isNotEmpty ? exSpots.last.y : 0.0;

      if (mounted) {
        setState(() {
          _inflationSpots = infSpots;
          _gdpSpots = gdpSpots;

          _fiscalData = [
            {
              'name': 'Inflation (Consumer Prices)',
              'value': '${latestInf.toStringAsFixed(2)}%',
              'color': const Color(0xFFE57373),
              'progress': (latestInf.abs() / 100).clamp(0.0, 1.0),
            },
            {
              'name': 'GDP Growth (Annual)',
              'value': '${latestGdp.toStringAsFixed(2)}%',
              'color': const Color(0xFF4CAF82),
              'progress': ((latestGdp + 15) / 30).clamp(0.0, 1.0), // Normalized for visualization
            },
            {
              'name': 'Official Exchange Rate',
              'value': '${latestEx.toStringAsFixed(2)} LKR',
              'color': const Color(0xFF2196F3),
              'progress': (latestEx / 400).clamp(0.0, 1.0), // Normalized against 400LKR cap
            },
          ];
        });
      }
    } catch (e) {
      debugPrint('World Bank API Error: $e');
    }
  }

  // Account Menu and dialog logic remains unchanged...
  void _showAccountMenu() {
    // ... [Content removed for brevity, keep your original _showAccountMenu implementation] ...
  }

  Future<void> _showEditAccountDialog() async {
    // ... [Content removed for brevity, keep your original _showEditAccountDialog implementation] ...
  }

  @override
  Widget build(BuildContext context) {
    final username = (_userData?['username'] as String?)?.trim();
    final profileUrl = _userData?['profileImageUrl'] as String?;
    final displayName = username != null && username.isNotEmpty ? username : 'User';

    return ScreenWithChatbot(
      bottomNavIndex: 0,
      child: Scaffold(
        backgroundColor: AppColors.panelTeal,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(text: 'Econo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                            TextSpan(text: 'Smart', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: Colors.white)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountDetailsPage())),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
                          child: profileUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Greeting
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi, $displayName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                        const Text('Good Morning', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Row(
                          children: const [
                            Icon(Icons.location_on, color: AppColors.gold, size: 13),
                            SizedBox(width: 3),
                            Text('LIVE • COLOMBO', style: TextStyle(color: AppColors.gold, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Total Balance Card
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
                          right: -20, bottom: -20,
                          child: Container(width: 110, height: 110, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle)),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text('Rs.${_totalBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Income / Expense Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _StatCard(label: 'Income', amount: 'Rs.${_totalIncome.toStringAsFixed(2)}', icon: Icons.arrow_outward, iconColor: AppColors.primaryTeal),
                      const SizedBox(width: 14),
                      _StatCard(label: 'Expense', amount: 'Rs.${_totalExpenses.toStringAsFixed(2)}', icon: Icons.south_east, iconColor: Colors.blueAccent),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Live API Rate Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _RateCard(
                        label: 'BRENT CRUDE',
                        value: _oilPrice,
                        change: 'USD/BBL',
                        isPositive: null,
                      ),
                      const SizedBox(width: 8),
                      _RateCard(
                        label: 'GOLD XAU',
                        value: _goldPrice,
                        change: 'USD/OZ',
                        isPositive: null,
                      ),
                      const SizedBox(width: 8),
                      _RateCard(
                        label: 'USD/LKR',
                        value: _usdRate,
                        change: 'MARKET',
                        isPositive: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Rates update in real-time', style: TextStyle(color: Colors.white30, fontSize: 10)),
                const SizedBox(height: 16),

                // Fiscal Vulnerability List (World Bank Data)
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
                            Text('FISCAL VULNERABILITY', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                            SizedBox(width: 6),
                            Icon(Icons.trending_up, color: AppColors.gold, size: 16),
                          ],
                        ),
                        const Text('Live data sourced from The World Bank API', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        const SizedBox(height: 14),
                        
                        if (_fiscalData.isEmpty)
                          const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2))),
                          
                        ..._fiscalData.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    Text(item['value'], style: TextStyle(color: item['color'], fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: item['progress'],
                                    backgroundColor: Colors.white.withOpacity(0.15),
                                    valueColor: AlwaysStoppedAnimation<Color>(item['color']),
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

                // World Bank Historical Chart
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
                            Text('ECONOMIC TRENDS (LAST 5 YEARS)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                            SizedBox(width: 6),
                            Icon(Icons.show_chart, color: AppColors.gold, size: 16),
                          ],
                        ),
                        const Text('Red: Inflation | Green: GDP Growth', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        const SizedBox(height: 20),
                        
                        SizedBox(
                          height: 140,
                          child: _inflationSpots.isEmpty && _gdpSpots.isEmpty
                              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                              : LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1)
                                    ),
                                    titlesData: FlTitlesData(
                                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (val, meta) => Text('${val.toInt()}%', style: const TextStyle(color: Colors.white54, fontSize: 9)),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 22,
                                          getTitlesWidget: (val, meta) => Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(val.toInt().toString(), style: const TextStyle(color: Colors.white54, fontSize: 9)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      // Inflation Line
                                      if (_inflationSpots.isNotEmpty)
                                        LineChartBarData(
                                          spots: _inflationSpots,
                                          isCurved: true,
                                          color: const Color(0xFFE57373),
                                          barWidth: 3,
                                          isStrokeCapRound: true,
                                          dotData: const FlDotData(show: true),
                                        ),
                                      // GDP Growth Line
                                      if (_gdpSpots.isNotEmpty)
                                        LineChartBarData(
                                          spots: _gdpSpots,
                                          isCurved: true,
                                          color: const Color(0xFF4CAF82),
                                          barWidth: 3,
                                          isStrokeCapRound: true,
                                          dotData: const FlDotData(show: true),
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

  const _RateCard({required this.label, required this.value, required this.change, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            Text(change, style: TextStyle(color: isPositive == null ? Colors.white54 : (isPositive! ? Colors.greenAccent : Colors.redAccent), fontSize: 11, fontWeight: FontWeight.w600)),
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

  const _StatCard({required this.label, required this.amount, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
            const SizedBox(height: 4),
            Text(amount, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}