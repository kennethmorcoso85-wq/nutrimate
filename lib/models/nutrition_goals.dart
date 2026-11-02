class NutritionGoals {
  const NutritionGoals({
    this.calories = 1800,
    this.carbs = 225,
    this.protein = 90,
    this.fat = 60,
  });

  final int calories;
  final int carbs;
  final int protein;
  final int fat;

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'carbs': carbs,
    'protein': protein,
    'fat': fat,
  };

  factory NutritionGoals.fromJson(Map<String, dynamic> json) => NutritionGoals(
    calories: (json['calories'] as num?)?.toInt() ?? 1800,
    carbs: (json['carbs'] as num?)?.toInt() ?? 225,
    protein: (json['protein'] as num?)?.toInt() ?? 90,
    fat: (json['fat'] as num?)?.toInt() ?? 60,
  );
}
