// lib/education_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/article_detail_screen.dart';
import 'package:freshlens_ai_app/models/article_model.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'package:freshlens_ai_app/widgets/article_list_item.dart';
import 'package:freshlens_ai_app/widgets/featured_article_card.dart';


class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // --- [DIKEMBALIKAN] Data dummy sebagai fallback ---
  final Article featuredArticleDummy = Article(
    title: '5 Cara Kreatif Mengolah Sisa Nasi Menjadi Hidangan Lezat',
    category: 'Tips & Trik',
    author: 'FreshLens Team',
    imageUrl: 'assets/images/food_waste.png',
    content: 'Sisa nasi seringkali berakhir di tempat sampah. Padahal, dengan sedikit kreativitas, Anda bisa mengubahnya menjadi hidangan yang menggugah selera...\n\n(Isi artikel lengkap di sini)',
    isFeatured: true,
  );

  final List<Article> otherArticlesDummy = [
    Article(
      title: 'Mengenal Eco Enzyme: Manfaat dan Cara Membuatnya',
      category: 'Gaya Hidup',
      author: 'Komunitas Lestari',
      imageUrl: 'assets/images/eco_enzyme.png',
      content: 'Eco enzyme adalah larutan serbaguna yang dihasilkan dari fermentasi sisa buah dan sayuran. Sangat ramah lingkungan dan memiliki banyak manfaat...\n\n(Isi artikel lengkap di sini)',
    ),
    Article(
      title: 'Panduan Menyimpan Sayuran Agar Tetap Segar Lebih Lama',
      category: 'Penyimpanan',
      author: 'Dapur Hijau',
      imageUrl: 'assets/images/fruits_vegetables.png',
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade50,
            Colors.green.shade200,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Edukasi'),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getArticles(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
            
            }
            
            List<Article> allArticles;
            // [DIUBAH] Gunakan data Firebase jika ada, jika tidak, gunakan data dummy
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              allArticles = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Article(
                  title: data['title'] ?? 'Tanpa Judul',
                  category: data['category'] ?? 'Umum',
                  author: data['author'] ?? 'Anonim',
                  imageUrl: data['imageUrl'] ?? '',
                  content: data['content'] ?? '',
                  isFeatured: data['isFeatured'] ?? false,
                );
              }).toList();
            } else {
              // Jika tidak ada data dari Firebase, pakai data dummy
              allArticles = [featuredArticleDummy, ...otherArticlesDummy];
            }

            final featuredArticle = allArticles.firstWhere(
              (a) => a.isFeatured,
              orElse: () => allArticles.first,
            );
            final otherArticles = allArticles.where((a) => a != featuredArticle).toList();

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                FeaturedArticleCard(
                  article: featuredArticle,
                  onTap: () => _navigateToDetail(featuredArticle),
                ),
                const SizedBox(height: 24),
                if (otherArticles.isNotEmpty)
                  Text(
                    'Topik Lainnya',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                const SizedBox(height: 8),
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
            );
          },
        ),
      ),
    );
  }
}