import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'news_article.dart';

class NewsApiService {
  String _getApiKey(String keyName) {
    return dotenv.env[keyName] ?? '';
  }

  Future<List<NewsArticle>> fetchEconomicNews() async {
    final finnhubKey = _getApiKey('FINNHUB_API_KEY');
    final marketAuxKey = _getApiKey('MARKETAUX_API_KEY');

    final finnhubUrl = 'https://finnhub.io/api/v1/news?category=general&token=$finnhubKey';
    final marketAuxUrl = 'https://api.marketaux.com/v1/news/all?language=en&api_token=$marketAuxKey';

    try {
      final List<http.Response> responses = await Future.wait([
        http.get(Uri.parse(finnhubUrl)),
        http.get(Uri.parse(marketAuxUrl)),
      ]);

      final finnhubResponse = responses[0];
      final marketAuxResponse = responses[1];

      List<NewsArticle> combinedArticles = [];

      if (finnhubResponse.statusCode == 200) {
        final List<dynamic> finnhubData = jsonDecode(finnhubResponse.body);
        final finnhubArticles = finnhubData.map((json) => NewsArticle.fromFinnhub(json)).toList();
        combinedArticles.addAll(finnhubArticles);
      } else {
        print('Finnhub Error: ${finnhubResponse.statusCode}'); 
      }

      if (marketAuxResponse.statusCode == 200) {
        final Map<String, dynamic> marketAuxData = jsonDecode(marketAuxResponse.body);
        final List<dynamic> articlesJson = marketAuxData['data'] ?? [];
        final marketAuxArticles = articlesJson.map((json) => NewsArticle.fromMarketAux(json)).toList();
        combinedArticles.addAll(marketAuxArticles);
      } else {
        print('MarketAux Error: ${marketAuxResponse.statusCode}');
      }

      combinedArticles.sort((a, b) => b.rawDate.compareTo(a.rawDate));

      return combinedArticles;
    } catch (e) {
      throw Exception('Error fetching combined news: $e');
    }
  }
}