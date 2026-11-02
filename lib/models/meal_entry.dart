class MealEntry {
  const MealEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String category;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'calories': calories,
    'carbs': carbs,
    'protein': protein,
    'fat': fat,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MealEntry.fromJson(Map<String, dynamic> json) => MealEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String? ?? 'Snack',
    calories: (json['calories'] as num).toInt(),
    carbs: (json['carbs'] as num).toInt(),
    protein: (json['protein'] as num).toInt(),
    fat: (json['fat'] as num).toInt(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
