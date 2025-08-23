// lib/education_screen.dart (Perbaikan Optimasi)

import 'package:flutter/material.dart';
import 'featured_article_card.dart';
import 'article_list_item.dart';
import 'recipe_webview_screen.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final featuredArticle = {
      'image': 'assets/images/fruits_vegetables.png',
      'title': 'Tips untuk Pemindaian yang Efektif',
      'time': '2 Hari yang lalu',
      'url': 'https://www.cnnindonesia.com/teknologi/20210304192731-185-613867/7-tips-memotret-makanan-keren-cuma-pakai-kamera-ponsel',
    };

    final List<Map<String, String>> dummyArticles = [
      {'image': 'assets/images/lettuce.png', 'source': 'Kompas.com', 'title': '6 Cara Agar Selada Tetap Segar Seminggu', 'time': '11 jam yang lalu', 'url': 'https://www.kompas.com/food/read/2021/06/18/140800375/6-cara-agar-selada-tetap-segar-seminggu-tips-untuk-penjual-sayur'},
      {'image': 'assets/images/food_waste.png', 'source': 'Waste4Change', 'title': 'Sampah Makanan Mendominasi Timbulan Sampah di Indonesia', 'time': 'Kemarin', 'url': 'https://waste4change.com/blog/sampah-makanan-mendominasi-timbulan-sampah-nasional-indonesia/'},
      {'image': 'assets/images/eco_enzyme.png', 'source': 'DLH Grobogan', 'title': 'Membuat Eco Enzyme dari Kulit Buah dan Sayur', 'time': '2 Hari yang lalu', 'url': 'https://dlh.grobogan.go.id/info/artikel/89-membuat-eco-enzyme-dari-kulit-buah-dan-sayur'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      appBar: AppBar(
        title: const Text('Edukasi'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          FeaturedArticleCard(
            imagePath: featuredArticle['image']!,
            title: featuredArticle['title']!,
            time: featuredArticle['time']!,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeWebviewScreen(initialUrl: featuredArticle['url']!, itemTitle: featuredArticle['title']!)));
            },
          ),
          const SizedBox(height: 24),
          const Text('Edukasi dan Tips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // PERBAIKAN DI SINI: .toList() dihapus
          ...dummyArticles.map((article) {
            return Column(
              children: [
                ArticleListItem(
                  imagePath: article['image']!,
                  source: article['source']!,
                  title: article['title']!,
                  time: article['time']!,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeWebviewScreen(initialUrl: article['url']!, itemTitle: article['source']!)));
                  },
                ),
                const Divider(),
              ],
            );
          }),
        ],
      ),
    );
  }
}