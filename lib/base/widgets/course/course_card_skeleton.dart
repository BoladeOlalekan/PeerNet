import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';

class CourseCardSkeleton extends StatelessWidget {
  final double? width;
  final EdgeInsetsGeometry? margin;

  const CourseCardSkeleton({super.key, this.width, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: margin,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppStyles.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppStyles.inputBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const Spacer(),
            Container(
              width: 100,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
