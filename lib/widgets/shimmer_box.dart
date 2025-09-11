// lib/widgets/shimmer_box.dart
import 'package:flutter/material.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const RoundedRectangleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: Colors.grey[300]!,
        shape: shapeBorder,
      ),
    );
  }
}