import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A shimmering placeholder grid matching the shelf's layout, shown while
/// the first page of ebooks is loading — much friendlier than a bare
/// spinner for a visually rich screen like a bookshelf.
class ShelfLoadingSkeleton extends StatelessWidget {
  const ShelfLoadingSkeleton({super.key, this.itemCount = 12});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF8B5E3C).withOpacity(0.5),
      highlightColor: const Color(0xFFcba87c).withOpacity(0.5),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
