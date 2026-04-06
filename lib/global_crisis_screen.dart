import 'package:flutter/material.dart';
import 'package:econosmart/app_colors.dart';
import 'package:econosmart/economic_data_service.dart';
import 'package:econosmart/news_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:econosmart/floating_chatbot.dart';

class GlobalCrisisScreen extends StatefulWidget {
  const GlobalCrisisScreen({super.key});

  @override
  State<GlobalCrisisScreen> createState() => _GlobalCrisisScreenState();
}

class _GlobalCrisisScreenState extends State<GlobalCrisisScreen> {
  final _econService = EconomicDataService();
  final List<CrisisEvent> _events = const [
    CrisisEvent(
      tag: 'LOGISTICS',
      severity: 'HIGH IMPACT',
      title: 'Red Sea Maritime Tensions',
      description:
          'Increased freight costs leading to import duties affecting supply chains.',
      pressure: 0.185,
      reserveImpact: '-\$450M Est.',
      response: 'Active Monitor',
      color: Color(0xFFECB22E),
    ),
    CrisisEvent(
      tag: 'TRADE',
      severity: 'MEDIUM',
      title: 'Global Semiconductor Shortage',
      description:
          'Tech export slowdown affecting tax revenue from IT sector across the region.',
      pressure: 0.072,
      reserveImpact: '-\$210M Est.',
      response: 'Active Monitor',
      color: Color(0xFF6C5DD3),
    ),
    CrisisEvent(
      tag: 'ENERGY',
      severity: 'CRITICAL',
      title: 'Oil Production Cuts (OPEC+)',
      description:
          'Direct pressure on CPC subsidies and foreign reserves from global supply cuts.',
      pressure: 0.241,
      reserveImpact: '-\$450M Est.',
      response: 'Active Monitor',
      color: Color(0xFFEF5A5A),
    ),
  ];

  List<NewsModel> _news = [];
  bool _loading = true;
  Map<String, double> _rates = {
    'LKR': 320.0,
    'GOLD': 215000.0,
    'OCTANE92': 345.5
  };
  Map<String, dynamic> _fuelData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    final news = await _econService.fetchEconomyNews();
    final rates = await _econService.getLiveRates();
    final fuelData = _econService.getSriLankaFuelPrices();

    setState(() {
      _news = news;
      _rates = rates;
      _fuelData = fuelData;
      _loading = false;
    });

    if (_news.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Breaking Economic Insight: ${_news.first.title}'),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithChatbot(
      bottomNavIndex: 3,
      child: Scaffold(
        backgroundColor: AppColors.panelTeal,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.gold,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 90),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Global Crisis Lab',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'World events mapped to Sri Lanka economy',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _StatusBadgeRow(),
                      const SizedBox(height: 16),
                      if (_news.isNotEmpty) _buildNewsNotification(_news.first),
                      _buildSnapshotCard(),
                      const SizedBox(height: 20),
                      const Text(
                        'Sri Lanka Impact',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildImpactGrid(),
                      const SizedBox(height: 18),
                      const Text(
                        'Crisis Tracker',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                ..._events.map((event) => _CrisisStrengthCard(event: event)),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: const [
                      Text(
                        'Economic News',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.rss_feed, color: AppColors.gold, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  )
                else
                  ..._news.map((item) => _NewsTile(news: item)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsNotification(NewsModel latestNews) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: AppColors.gold, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LATEST ECONOMIC NOTIFICATION',
                  style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 10),
                ),
                Text(
                  latestNews.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Situation',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            label: 'USD / LKR',
            value: _rates['LKR']?.toStringAsFixed(2) ?? '320.00',
            note: 'Import pressure from currency volatility',
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            label: 'Fuel price',
            value: _fuelData['octane92'] != null
                ? '${_fuelData['octane92']['price'].toStringAsFixed(0)} LKR/L'
                : '345 LKR/L',
            note: 'CPC subsidy burden rising',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    required String note,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImpactGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          Expanded(
            child: _SimpleImpactTile(
              title: 'Reserve Pressure',
              value: '24%',
              accent: AppColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SimpleImpactTile(
              title: 'Import Cost',
              value: '+18.5%',
              accent: Colors.tealAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class CrisisEvent {
  final String tag;
  final String severity;
  final String title;
  final String description;
  final double pressure;
  final String reserveImpact;
  final String response;
  final Color color;

  const CrisisEvent({
    required this.tag,
    required this.severity,
    required this.title,
    required this.description,
    required this.pressure,
    required this.reserveImpact,
    required this.response,
    required this.color,
  });
}

class _StatusBadgeRow extends StatelessWidget {
  const _StatusBadgeRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _StatusPill(label: 'LIVE', color: AppColors.gold),
        SizedBox(width: 10),
        _StatusPill(label: 'SRI LANKA FOCUS', color: Colors.white24),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CrisisStrengthCard extends StatelessWidget {
  final CrisisEvent event;
  const _CrisisStrengthCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.primaryTeal,
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TagChip(label: event.tag, background: Colors.white12),
              const SizedBox(width: 8),
              _TagChip(
                  label: event.severity,
                  background: event.color.withOpacity(0.18),
                  color: event.color),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            event.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            event.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: event.pressure,
            color: event.color,
            backgroundColor: Colors.white10,
            minHeight: 6,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRESSURE: ${(event.pressure * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                event.reserveImpact,
                style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'RESPONSE: ${event.response}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SimpleImpactTile extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;
  const _SimpleImpactTile({
    required this.title,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color color;
  const _TagChip({
    required this.label,
    required this.background,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  final NewsModel news;
  const _NewsTile({required this.news});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(news.url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  news.source,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  news.pubDate,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              news.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              news.description,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
