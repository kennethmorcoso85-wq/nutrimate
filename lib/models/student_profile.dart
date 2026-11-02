class StudentProfile {
  const StudentProfile({
    required this.name,
    required this.role,
    this.grade = '',
    this.height = 150,
    this.weight = 45,
  });

  final String name;
  final String role;
  final String grade;
  final double height;
  final double weight;

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
    'grade': grade,
    'height': height,
    'weight': weight,
  };

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
    name: json['name'] as String? ?? 'User',
    role: json['role'] as String? ?? 'User',
    grade: json['grade'] as String? ?? '',
    height: (json['height'] as num?)?.toDouble() ?? 150,
    weight: (json['weight'] as num?)?.toDouble() ?? 45,
  );
}
