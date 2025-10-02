import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:peer_net/base/res/styles/app_styles.dart' as AppStyles;

class CourseCard extends StatelessWidget {
  final String courseCode;
  final String courseName;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.onTap, 
    required this.courseCode, 
    required this.courseName,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size.width * 0.4,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              FluentSystemIcons.ic_fluent_book_formula_compatibility_filled,
              size: 45,
              color: AppStyles.accent,
            ),
            const SizedBox(height: 8),
            Text(
              courseCode,
              style: AppStyles.AppStyles.subStyle.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w500
              ),
            ),
            Text(
              courseName,
              style: AppStyles.AppStyles.subStyle.copyWith(
                fontWeight: FontWeight.w400
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
