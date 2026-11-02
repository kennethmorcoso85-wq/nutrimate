class MealRecord {
  final String id;
  final int? foodId;
  final double servings;
  final String name;
  final String category;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String notes;
  final DateTime createdAt;

  MealRecord({
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.foodId,
    this.servings = 1,
    this.notes = '',
    DateTime? createdAt,
  }) : id = DateTime.now().microsecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now();

  MealRecord._({
    required this.id,
    required this.foodId,
    required this.servings,
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'food': foodId,
    'servings': servings,
    'name': name,
    'category': category,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MealRecord.fromJson(Map<String, dynamic> json) => MealRecord._(
    id: json['id'].toString(),
    foodId: (json['food'] as num?)?.toInt(),
    servings: (json['servings'] as num?)?.toDouble() ?? 1,
    name: json['name'] as String,
    category: json['category'] as String,
    calories: json['calories'] as int,
    protein: json['protein'] as int,
    carbs: json['carbs'] as int,
    fat: json['fat'] as int,
    notes: json['notes'] as String? ?? '',
    createdAt: DateTime.parse(
      (json['created_at'] ?? json['createdAt']) as String,
    ),
  );
}
