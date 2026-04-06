import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:econosmart/models/news_model.dart';

class EconomicDataService {
  static const String _newsApiKey = 'c829089828c749feb22ac28ddd0bb10d';

  Future<Map<String, double>> getLiveRates() async {
    try {
      final res = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/USD'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rates = data['rates'] as Map<String, dynamic>;
        return {
          'LKR': (rates['LKR'] ?? 314.80).toDouble(),
          'GOLD': 388160.0, // 24K Pawuma
          'OCTANE92': 398.00,
          'BRENT_CRUDE': 109.03,
        };
      }
    } catch (e) {
      print('Rate fetch error: $e');
    }
    return {
      'LKR': 314.80,
      'GOLD': 388160.0,
      'OCTANE92': 398.00,
      'BRENT_CRUDE': 109.03
    };
  }

  Map<String, dynamic> getSriLankaFuelPrices() {
    return {
      'octane92': {'price': 398.00, 'unit': 'LKR/L', 'change': '+15.3%'},
      'octane95': {'price': 455.00, 'unit': 'LKR/L', 'change': '+23.6%'},
      'autoDiesel': {'price': 293.00, 'unit': 'LKR/L', 'change': '+5.2%'},
      'superDiesel': {'price': 325.00, 'unit': 'LKR/L', 'change': '+6.1%'},
      'kerosene': {'price': 182.00, 'unit': 'LKR/L', 'change': '-2.1%'},
      'lastUpdated': 'April 2026',
      'source': 'CEYPETCO',
      'sourceUrl': 'https://www.ceypetco.gov.lk',
    };
  }

  Future<List<NewsModel>> fetchEconomyNews() async {
    if (_newsApiKey.isNotEmpty) {
      final apiNews = await _fetchNewsFromNewsApi();
      if (apiNews.isNotEmpty) return apiNews;
    }
    return _fetchEconomyNewsFallback();
  }

  Future<List<NewsModel>> _fetchNewsFromNewsApi() async {
    final List<NewsModel> result = [];
    try {
      final uri = Uri.https('newsapi.org', '/v2/everything', {
        'q': 'Sri Lanka economy OR inflation OR IMF OR crisis OR dollar',
        'language': 'en',
        'pageSize': '10',
        'sortBy': 'publishedAt',
        'apiKey': _newsApiKey,
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final articles = data['articles'] as List<dynamic>?;
        if (articles != null) {
          for (final raw in articles) {
            final article = raw as Map<String, dynamic>;
            final source = article['source'] as Map<String, dynamic>?;
            final title = article['title'] as String? ?? '';
            final description = article['description'] as String? ?? '';
            final url = article['url'] as String? ?? '';
            final pubDate = article['publishedAt'] as String? ?? '';
            if (title.isNotEmpty && url.isNotEmpty) {
              result.add(
                NewsModel(
                  title: title,
                  description: description,
                  url: url,
                  source: source?['name'] as String? ?? 'NewsAPI',
                  pubDate: pubDate.split('T').first,
                ),
              );
            }
          }
        }
      } else {
        print('NewsAPI fetch failed: ${res.statusCode}');
      }
    } catch (e) {
      print('NewsAPI error: $e');
    }
    return result;
  }

  Future<List<NewsModel>> _fetchEconomyNewsFallback() async {
    final List<NewsModel> allNews = [];
    final feeds = [
      {
        'url': 'https://feeds.bbci.co.uk/news/world/asia/rss.xml',
        'source': 'BBC News',
      },
      {'url': 'https://economynext.com/feed/', 'source': 'Economy Next'},
      {'url': 'https://www.dailymirror.lk/rss', 'source': 'Daily Mirror LK'},
    ];

    for (final feed in feeds) {
      try {
        final res = await http.get(
          Uri.parse(feed['url']!),
          headers: {'User-Agent': 'EconoSmartApp/1.0'},
        ).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final items = _parseRss(res.body, feed['source']!);
          allNews.addAll(items.take(5));
        }
      } catch (e) {
        print('Feed error ${feed["source"]}: $e');
      }
    }

    if (allNews.isEmpty) return _getStaticNewsLinks();
    return allNews;
  }

  List<NewsModel> _parseRss(String xmlBody, String source) {
    final List<NewsModel> items = [];
    try {
      final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
      final titleRegex = RegExp(
        r'<title><!\[CDATA\[(.*?)\]\]>|<title>(.*?)</title>',
      );
      final linkRegex = RegExp(r'<link>(.*?)</link>');
      final descRegex = RegExp(
        r'<description><!\[CDATA\[(.*?)\]\]>|<description>(.*?)</description>',
      );
      final dateRegex = RegExp(r'<pubDate>(.*?)</pubDate>');

      for (final match in itemRegex.allMatches(xmlBody)) {
        final item = match.group(1) ?? '';
        final title = titleRegex.firstMatch(item)?.group(1) ??
            titleRegex.firstMatch(item)?.group(2) ??
            '';
        final link = linkRegex.firstMatch(item)?.group(1) ?? '';
        final desc = descRegex.firstMatch(item)?.group(1) ??
            descRegex.firstMatch(item)?.group(2) ??
            '';
        final date = dateRegex.firstMatch(item)?.group(1) ?? '';

        if (title.isNotEmpty &&
            (title.toLowerCase().contains('sri lanka') ||
                title.toLowerCase().contains('economy') ||
                title.toLowerCase().contains('inflation') ||
                title.toLowerCase().contains('fuel') ||
                title.toLowerCase().contains('dollar') ||
                title.toLowerCase().contains('imf') ||
                title.toLowerCase().contains('crisis'))) {
          items.add(
            NewsModel(
              title: title.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
              description: desc.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
              url: link.trim(),
              source: source,
              pubDate: date.trim(),
            ),
          );
        }
      }
    } catch (e) {
      print('RSS parse error: $e');
    }
    return items;
  }

  List<NewsModel> _getStaticNewsLinks() {
    return [
      NewsModel(
        title: 'Sri Lanka Economy Recovery: IMF Programme Update',
        description:
            'Sri Lanka continues IMF-backed economic reform programme.',
        url: 'https://www.bbc.com/news/topics/c2vdnvyt239t/sri-lanka',
        source: 'BBC News',
        pubDate: 'Latest',
      ),
      NewsModel(
        title: 'USD/LKR Exchange Rate Movements – Economy Next',
        description:
            'Latest updates on Sri Lankan Rupee performance against US Dollar.',
        url: 'https://economynext.com/category/forex/',
        source: 'Economy Next',
        pubDate: 'Latest',
      ),
      NewsModel(
        title: 'Red Sea Crisis Impact on Sri Lanka Import Costs',
        description:
            'Freight disruptions via Red Sea adding pressure to Sri Lanka\'s import bill.',
        url: 'https://www.reuters.com/world/asia-pacific/sri-lanka/',
        source: 'Reuters',
        pubDate: 'Latest',
      ),
      NewsModel(
        title: 'CEYPETCO Fuel Price Revision – Official Statement',
        description:
            'Latest fuel price revision by Ceylon Petroleum Corporation.',
        url: 'https://www.ceypetco.gov.lk',
        source: 'CEYPETCO',
        pubDate: 'April 2026',
      ),
      NewsModel(
        title: 'Global Semiconductor Shortage: SL Tech Exports Slowdown',
        description:
            'Tech export revenue declining as global chip shortage affects IT sector.',
        url: 'https://economynext.com/sri-lanka-it-exports/',
        source: 'Economy Next',
        pubDate: 'Latest',
      ),
      NewsModel(
        title: 'OPEC+ Output Cuts Push Oil Prices Higher',
        description: 'OPEC+ production cuts driving global crude prices.',
        url: 'https://www.bbc.com/news/business/market-data',
        source: 'BBC Business',
        pubDate: 'Latest',
      ),
    ];
  }
}
