class NewsModel {
  final String title;
  final String description;
  final String url;
  final String source;
  final String pubDate;
  final String imageUrl;

  NewsModel({
    required this.title,
    required this.description,
    required this.url,
    required this.source,
    required this.pubDate,
    this.imageUrl = '',
  });
}
