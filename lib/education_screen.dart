// lib/education_screen.dart

import 'package:flutter/material.dart';
import 'featured_article_card.dart';
import 'article_list_item.dart';
import 'recipe_webview_screen.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy untuk konten (tidak berubah)
    final featuredArticle = {
      'image': 'assets/images/fruits_vegetables.png',
      'title': 'Tips Memotret Makanan Agar Terlihat Profesional',
      'time': '2 Hari yang lalu',
      'url': 'https://www.cnnindonesia.com/teknologi/20210304192731-185-613867/7-tips-memotret-makanan-keren-cuma-pakai-kamera-ponsel',
    };

    final List<Map<String, String>> dummyArticles = [
      {'image': 'assets/images/lettuce.png', 'source': 'Kompas.com', 'title': '6 Cara Jitu Agar Selada Tetap Segar Selama Seminggu', 'time': '11 jam yang lalu', 'url': 'https://www.kompas.com/food/read/2021/06/18/140800375/6-cara-agar-selada-tetap-segar-seminggu-tips-untuk-penjual-sayur'},
      {'image': 'assets/images/food_waste.png', 'source': 'Waste4Change', 'title': 'Sampah Makanan Mendominasi Timbulan Sampah di Indonesia', 'time': 'Kemarin', 'url': 'https://waste4change.com/blog/sampah-makanan-mendominasi-timbulan-sampah-nasional-indonesia/'},
      {'image': 'assets/images/eco_enzyme.png', 'source': 'DLH Grobogan', 'title': 'Membuat Eco Enzyme dari Sampah Kulit Buah dan Sayur', 'time': '2 Hari yang lalu', 'url': 'https://dlh.grobogan.go.id/info/artikel/89-membuat-eco-enzyme-dari-kulit-buah-dan-sayur'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      appBar: AppBar(
        title: const Text('Edukasi'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Kartu Unggulan
          FeaturedArticleCard(
            imagePath: featuredArticle['image']!,
            title: featuredArticle['title']!,
            time: featuredArticle['time']!,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeWebviewScreen(initialUrl: featuredArticle['url']!, itemTitle: 'Tips Fotografi')));
            },
          ),
          const SizedBox(height: 24),

          // Judul Bagian
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'Bacaan Terbaru',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          // Daftar Artikel
          ListView.separated(
            itemCount: dummyArticles.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final article = dummyArticles[index];
              return ArticleListItem(
                imagePath: article['image']!,
                source: article['source']!,
                title: article['title']!,
                time: article['time']!,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeWebviewScreen(initialUrl: article['url']!, itemTitle: article['source']!)));
                },
              );
            },
          ),
        ],
      ),
    );
  }
}