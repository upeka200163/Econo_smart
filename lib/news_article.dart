class NewsArticle {
  final String title;
  final String source;
  final String url;
  final String? imageUrl;
  final String date;
  final DateTime rawDate;

  NewsArticle({
    required this.title,
    required this.source,
    required this.url,
    this.imageUrl,
    required this.date,
    required this.rawDate,
  });

  factory NewsArticle.fromFinnhub(Map<String, dynamic> json) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch((json['datetime'] ?? 0) * 1000);
    
    return NewsArticle(
      title: json['headline'] ?? 'No Title',
      source: json['source'] ?? 'Finnhub',
      url: json['url'] ?? '',
      imageUrl: json['image'],
      date: "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}",
      rawDate: dateTime,
    );
  }

  factory NewsArticle.fromMarketAux(Map<String, dynamic> json) {
    final dateTime = DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now();

    return NewsArticle(
      title: json['title'] ?? 'No Title',
      source: json['source'] ?? 'MarketAux',
      url: json['url'] ?? '',
      imageUrl: json['image_url'], 
      date: "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}",
      rawDate: dateTime,
    );
  }
}