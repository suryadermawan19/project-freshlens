// lib/article_list_item.dart

import 'package:flutter/material.dart';

class ArticleListItem extends StatelessWidget {
  final String imagePath;
  final String source;
  final String title;
  final String time;
  final VoidCallback onTap;

  const ArticleListItem({
    super.key,
    required this.imagePath,
    required this.source,
    required this.title,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            // Teks di sebelah kiri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      height: 1.4, // Jarak antar baris teks
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Gambar di sebelah kanan
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}