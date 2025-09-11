// lib/education_screen.dart

import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/article_detail_screen.dart';
import 'package:freshlens_ai_app/models/article_model.dart';
import 'package:freshlens_ai_app/widgets/article_list_item.dart';
import 'package:freshlens_ai_app/widgets/featured_article_card.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  // Data dummy untuk artikel
  // Nantinya, data ini akan diambil dari Firebase atau CMS
  final Article featuredArticle = Article(
    title: '5 Cara Kreatif Mengolah Sisa Nasi Menjadi Hidangan Lezat',
    category: 'Tips & Trik',
    author: 'FreshLens Team',
    imageUrl: 'assets/images/food_waste.png', // Ganti dengan path aset yang sesuai
    content: 'Sisa nasi seringkali berakhir di tempat sampah. Padahal, dengan sedikit kreativitas, Anda bisa mengubahnya menjadi hidangan yang menggugah selera...\n\n(Isi artikel lengkap di sini)',
  );

  final List<Article> otherArticles = [
    Article(
      title: 'Mengenal Eco Enzyme: Manfaat dan Cara Membuatnya',
      category: 'Gaya Hidup',
      author: 'Komunitas Lestari',
      imageUrl: 'assets/images/eco_enzyme.png', // Ganti dengan path aset yang sesuai
      content: 'Eco enzyme adalah larutan serbaguna yang dihasilkan dari fermentasi sisa buah dan sayuran. Sangat ramah lingkungan dan memiliki banyak manfaat...\n\n(Isi artikel lengkap di sini)',
    ),
    Article(
      title: 'Panduan Menyimpan Sayuran Agar Tetap Segar Lebih Lama',
      category: 'Penyimpanan',
      author: 'Dapur Hijau',
      imageUrl: 'assets/images/fruits_vegetables.png', // Ganti dengan path aset yang sesuai
      content: 'Menyimpan sayuran dengan benar adalah kunci untuk menjaga kesegaran dan nutrisinya. Berikut adalah beberapa tips yang bisa Anda coba...\n\n(Isi artikel lengkap di sini)',
    ),
  ];

  void _navigateToDetail(Article article) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ArticleDetailScreen(article: article)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edukasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Artikel Utama
          FeaturedArticleCard(
            article: featuredArticle,
            onTap: () => _navigateToDetail(featuredArticle),
          ),
          const SizedBox(height: 24),

          // Judul Topik Lainnya
          Text(
            'Topik Lainnya',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),

          // Daftar Artikel Lainnya
          ListView.builder(
            itemCount: otherArticles.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final article = otherArticles[index];
              return ArticleListItem(
                article: article,
                onTap: () => _navigateToDetail(article),
              );
            },
          ),
        ],
      ),
    );
  }
}