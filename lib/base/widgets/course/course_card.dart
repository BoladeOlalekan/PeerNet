import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';

class CourseCard extends StatelessWidget {
  final String courseCode;
  final String courseName;
  final VoidCallback onTap;

  final double? width;
  final EdgeInsetsGeometry? margin;

  const CourseCard({
    super.key,
    required this.onTap,
    required this.courseCode,
    required this.courseName,
    this.width,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: margin,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppStyles.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppStyles.inputBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppStyles.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppStyles.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                FluentSystemIcons.ic_fluent_book_formula_compatibility_filled,
                size: 28,
                color: AppStyles.accentColor,
              ),
            ),
            const Spacer(),
            Text(
              courseCode,
              style: AppStyles.pageTitle.copyWith(
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              courseName,
              style: AppStyles.pageSubtitle.copyWith(
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
