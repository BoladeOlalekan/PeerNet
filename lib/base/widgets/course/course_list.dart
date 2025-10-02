import 'package:flutter/material.dart';
import 'package:peer_net/base/widgets/course/course_card.dart';
import 'package:peer_net/features/COURSES/models/course_model.dart';

class CourseList extends StatelessWidget {
  final List<CourseModel> courses; 
  final void Function(CourseModel course) onCourseTap;

  const CourseList({
    super.key,
    required this.courses,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.25,
      child: courses.isEmpty
          ? Center(
              child: Text(
                "No courses found",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return CourseCard(
                  onTap: () => onCourseTap(course), 
                  courseCode: course.courseCode, 
                  courseName: course.courseName,
                );
              },
            ),
    );
  }
}
