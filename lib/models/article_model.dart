// lib/models/article_model.dart

class Article {
  final String title;
  final String category;
  final String author;
  final String imageUrl;
  final String content;

  Article({
    required this.title,
    required this.category,
    required this.author,
    required this.imageUrl,
    required this.content,
  });
}