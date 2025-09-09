// lib/featured_article_card.dart

import 'package:flutter/material.dart';

class FeaturedArticleCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String time;
  final VoidCallback onTap;

  const FeaturedArticleCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black.withAlpha(100),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            // Gambar sebagai background
            Image.asset(
              imagePath,
              height: 220, // Sedikit lebih tinggi untuk dampak visual
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            // Lapisan gradien untuk keterbacaan teks
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(50),
                      Colors.black.withAlpha(220),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Teks di atas gradien
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            const Shadow(blurRadius: 4.0, color: Colors.black54)
                          ],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.white.withAlpha(230),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}