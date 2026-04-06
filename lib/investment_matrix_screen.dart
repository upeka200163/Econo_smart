import 'package:flutter/material.dart';
import 'package:econosmart/theme/app_colors.dart';
import 'package:econosmart/bottom_nav.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:econosmart/investment_detail_screen.dart';
import 'package:econosmart/economic_data_service.dart';

class InvestmentMatrixScreen extends StatefulWidget {
  const InvestmentMatrixScreen({super.key});

  @override
  State<InvestmentMatrixScreen> createState() => _InvestmentMatrixScreenState();
}

class _InvestmentMatrixScreenState extends State<InvestmentMatrixScreen> {
  final List<String> _filters = ['ALL', 'BANKS', 'INSURANCE', 'TREASURY'];
  final _econService = EconomicDataService();
  int _selectedFilter = 0;
  Map<String, double> _liveRates = {};
  bool _isLoadingRates = true;

  @override
  void initState() {
    super.initState();
    _loadMarketRates();
  }

  Future<void> _loadMarketRates() async {
    setState(() => _isLoadingRates = true);
    final rates = await _econService.getLiveRates();
    if (mounted) setState(() { _liveRates = rates; _isLoadingRates = false; });
  }

  final List<Map<String, dynamic>> _investments = [
    {
      'name': 'Sampath Bank',
      'type': 'FD (1YR)',
      'safety': 'HIGH',
      'rate': 11.5,
      'category': 'BANKS',
      'color': Color(0xFF4CAF82),
      'url': 'https://www.sampath.lk',
      'description':
          'Sampath Bank offers competitive fixed deposit rates with high security. Rated A+(lka) by Fitch Ratings.',
    },
    {
      'name': 'SL Govt Treasury',
      'type': 'T-BILL (91D)',
      'safety': 'SOVEREIGN',
      'rate': 10.8,
      'category': 'TREASURY',
      'color': AppColors.gold,
      'url': 'https://www.cbsl.gov.lk',
      'description':
          'Treasury Bills are backed by the Government of Sri Lanka, offering the highest level of capital safety.',
    },
    {
      'name': 'Softlogic Life',
      'type': 'Wealth Plan',
      'safety': 'MEDIUM',
      'rate': 15.1,
      'category': 'INSURANCE',
      'color': Color(0xFF4CAF82),
      'url': 'https://softlogiclife.lk',
      'description':
          'Wealth plans provide high returns combined with life insurance coverage, suitable for long-term growth.',
    },
  ];

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'BANKS':
        return Icons.account_balance;
      case 'TREASURY':
        return Icons.security;
      case 'INSURANCE':
        return Icons.health_and_safety;
      default:
        return Icons.trending_up;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 0
        ? _investments
        : _investments
            .where((i) => i['category'] == _filters[_selectedFilter])
            .toList();

    return Scaffold(
      backgroundColor: AppColors.panelTeal,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investment Matrix',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
                    const Text(
                      'Banks vs Insurance Comparison',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _buildMarketTicker(),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  itemBuilder: (ctx, i) {
                    final selected = _selectedFilter == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = i),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _filters[i],
                          style: TextStyle(
                            color:
                                selected ? AppColors.primaryTeal : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ...filtered.map(
                (inv) => Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => InvestmentDetailScreen(investment: inv)),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_getCategoryIcon(inv['category']), 
                              color: inv['color'], size: 24),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inv['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${inv['type']} • ${inv['safety']} SAFETY',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            '${inv['rate']}%',
                            style: TextStyle(
                              color: inv['color'],
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Smart Allocator AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Conditions favor Insurance Wealth Plans this month due to stabilizing inflation.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white38),
                        ),
                        child: const Text(
                          'Generate Portfolio Plan',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavWidget(currentIndex: 3),
    );
  }
}
