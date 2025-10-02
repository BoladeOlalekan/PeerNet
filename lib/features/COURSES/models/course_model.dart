class CourseModel {
  final String id;
  final String department;
  final int level;
  final String semester;
  final String courseCode;
  final String courseName;

  CourseModel({
    required this.id,
    required this.department,
    required this.level,
    required this.semester,
    required this.courseCode,
    required this.courseName,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
    id: json['id'],
    department: json['department'],
    level: json['level'],
    semester: json['semester'],
    courseCode: json['course_code'],
    courseName: json['course_name'],
  );
}
