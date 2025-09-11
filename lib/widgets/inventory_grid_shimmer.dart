// lib/widgets/inventory_grid_shimmer.dart
import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/widgets/shimmer_box.dart';
import 'package:shimmer/shimmer.dart';

class InventoryGridShimmer extends StatelessWidget {
  const InventoryGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 6, // Jumlah skeleton yang ditampilkan
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: ShimmerBox(width: double.infinity, height: 120)),
              SizedBox(height: 8),
              ShimmerBox(width: 100, height: 16),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerBox(width: 60, height: 12),
                  ShimmerBox(width: 50, height: 20, shapeBorder: StadiumBorder()),
                ],
              )
            ],
          );
        },
      ),
    );
  }
}
