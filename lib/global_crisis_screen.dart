import 'package:flutter/material.dart';
import 'package:econosmart/app_colors.dart';
import 'package:econosmart/economic_data_service.dart';
import 'package:econosmart/floating_chatbot.dart';
import 'package:econosmart/news_api_service.dart';
import 'package:econosmart/news_article.dart';
import 'package:econosmart/news_preview_card.dart';

class GlobalCrisisScreen extends StatefulWidget {
  const GlobalCrisisScreen({super.key});

  @override
  State<GlobalCrisisScreen> createState() => _GlobalCrisisScreenState();
}

class _GlobalCrisisScreenState extends State<GlobalCrisisScreen> {
  final _econService = EconomicDataService();
  final _apiService = NewsApiService();

  List<NewsArticle> _news = [];
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

    final rates = await _econService.getLiveRates();
    final fuelData = _econService.getSriLankaFuelPrices();
    List<NewsArticle> news = [];
    try {
      news = await _apiService.fetchEconomicNews();
    } catch (e) {
      debugPrint('Error fetching news: $e');
    }

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
                    ],
                  ),
                ),
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
                else if (_news.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No news available right now.', style: TextStyle(color: Colors.white70)),
                    ),
                  )
                else
                  ..._news.take(10).map((article) => NewsPreviewCard(
                        title: article.title,
                        sourceName: article.source,
                        articleUrl: article.url,
                        imageUrl: article.imageUrl,
                        publishedAt: article.date,
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsNotification(NewsArticle latestNews) {
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
