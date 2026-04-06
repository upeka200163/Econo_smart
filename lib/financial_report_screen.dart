import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:econosmart/app_colors.dart';
import 'package:econosmart/economic_data_service.dart';
import 'package:econosmart/floating_chatbot.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  final _econService = EconomicDataService();
  final TextEditingController _principalController = TextEditingController(text: '100000');
  final TextEditingController _rateController = TextEditingController(text: '11.5');
  final TextEditingController _yearsController = TextEditingController(text: '1');

  String _selectedCategory = 'All';
  String _calculatorResult = '';
  bool _loading = true;
  Map<String, double> _liveRates = {
    'LKR': 320.0,
    'GOLD': 215000.0,
    'OCTANE92': 345.5,
  };

  final List<InvestmentOption> _options = const [
    InvestmentOption(
      name: 'Sampath Bank',
      tier: 'FD (1YR) • HIGH SAFETY',
      rate: 11.5,
      category: 'Banks',
    ),
    InvestmentOption(
      name: 'Commercial Bank',
      tier: 'FD (1YR) • HIGH SAFETY',
      rate: 11.2,
      category: 'Banks',
    ),
    InvestmentOption(
      name: 'AIA Bank',
      tier: 'FD (1YR) • HIGH SAFETY',
      rate: 14.2,
      category: 'Banks',
    ),
    InvestmentOption(
      name: 'Softlogic Life',
      tier: 'FD (1YR) • HIGH SAFETY',
      rate: 15.1,
      category: 'Insurance',
    ),
    InvestmentOption(
      name: 'Treasury Bills',
      tier: '6M • GOVT SECURE',
      rate: 13.0,
      category: 'Treasury',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _refreshLiveData();
  }

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  Future<void> _refreshLiveData() async {
    setState(() {
      _loading = true;
    });
    final rates = await _econService.getLiveRates();
    setState(() {
      _liveRates = rates;
      _loading = false;
    });
  }

  void _calculateInterest() {
    final principal = double.tryParse(_principalController.text.replaceAll(',', '')) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final years = double.tryParse(_yearsController.text) ?? 0;

    if (principal <= 0 || rate <= 0 || years <= 0) {
      setState(() {
        _calculatorResult = 'Enter valid principal, rate and term.';
      });
      return;
    }

    final maturity = principal * (1 + rate / 100 * years);
    final interest = maturity - principal;
    setState(() {
      _calculatorResult =
          'Future value: Rs.${maturity.toStringAsFixed(0)}\nInterest earned: Rs.${interest.toStringAsFixed(0)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'All'
        ? _options
        : _options.where((item) => item.category == _selectedCategory).toList();

    return ScreenWithChatbot(
      bottomNavIndex: 1,
      child: Scaffold(
        backgroundColor: AppColors.panelTeal,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshLiveData,
            color: AppColors.gold,
            child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.show_chart, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Investment Matrix',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Banks vs Insurance Comparison',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All', 'Banks', 'Insurance', 'Treasury']
                      .map((category) => ChoiceChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            selectedColor: Colors.white70,
                            backgroundColor: Colors.white12,
                            labelStyle: TextStyle(
                              color: _selectedCategory == category
                                  ? AppColors.textDark
                                  : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 18),
              ...filtered.map((option) => _InvestmentCard(option: option)),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade700,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.auto_graph, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Smart Allocator AI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Conditions favor insurance wealth plans this month due to stabilizing inflation in SL.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse('https://economynext.com/');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: const Center(
                          child: Text(
                            'Generate Portfolio Plan',
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Market Data',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _MarketDataTile(
                                label: 'USD/LKR',
                                value: _liveRates['LKR']?.toStringAsFixed(2) ?? '320.00',
                                note: 'Latest exchange rate',
                              ),
                              const SizedBox(width: 12),
                              _MarketDataTile(
                                label: 'Fuel (92)',
                                value: '${_liveRates['OCTANE92']?.toStringAsFixed(0)} LKR',
                                note: 'Local fuel trend',
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _MarketDataTile(
                                  label: 'Gold Price',
                                  value: 'Rs.${_liveRates['GOLD']?.toStringAsFixed(0)}',
                                  note: 'Per tola estimate',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Data from open exchange rate API',
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              if (_loading)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
                                )
                              else
                                GestureDetector(
                                  onTap: _refreshLiveData,
                                  child: const Text(
                                    'Refresh',
                                    style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Interest Calculator',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CalculatorField(
                            label: 'Principal (Rs)',
                            controller: _principalController,
                            hint: '100000',
                          ),
                          const SizedBox(height: 14),
                          _CalculatorField(
                            label: 'Rate (%)',
                            controller: _rateController,
                            hint: '11.5',
                          ),
                          const SizedBox(height: 14),
                          _CalculatorField(
                            label: 'Term (Years)',
                            controller: _yearsController,
                            hint: '1',
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _calculateInterest,
                            child: const Text(
                              'Calculate Interest',
                              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_calculatorResult.isNotEmpty)
                            Text(
                              _calculatorResult,
                              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class InvestmentOption {
  final String name;
  final String tier;
  final double rate;
  final String category;

  const InvestmentOption({
    required this.name,
    required this.tier,
    required this.rate,
    required this.category,
  });
}

class _InvestmentCard extends StatelessWidget {
  final InvestmentOption option;
  const _InvestmentCard({required this.option});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    option.tier,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${option.rate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ANNUAL',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketDataTile extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  const _MarketDataTile({required this.label, required this.value, required this.note});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(note, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _CalculatorField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _CalculatorField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ],
    );
  }
}
