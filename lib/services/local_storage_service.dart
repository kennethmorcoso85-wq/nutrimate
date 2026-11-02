import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal_entry.dart';
import '../models/nutrition_goals.dart';
import '../models/student_profile.dart';

class LocalStorageService {
  static const _profileKey = 'nutrimate.profile';
  static const _goalsKey = 'nutrimate.goals';
  static const _mealsKey = 'nutrimate.meals';

  SharedPreferences? _preferences;

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  StudentProfile? loadProfile() {
    final value = _preferences!.getString(_profileKey);
    return value == null
        ? null
        : StudentProfile.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  NutritionGoals loadGoals() {
    final value = _preferences!.getString(_goalsKey);
    return value == null
        ? const NutritionGoals()
        : NutritionGoals.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  List<MealEntry> loadMeals() {
    final value = _preferences!.getString(_mealsKey);
    return value == null
        ? []
        : (jsonDecode(value) as List<dynamic>)
              .map((item) => MealEntry.fromJson(item as Map<String, dynamic>))
              .toList();
  }

  Future<void> saveProfile(StudentProfile profile) =>
      _preferences!.setString(_profileKey, jsonEncode(profile.toJson()));

  Future<void> saveGoals(NutritionGoals goals) =>
      _preferences!.setString(_goalsKey, jsonEncode(goals.toJson()));

  Future<void> saveMeals(List<MealEntry> meals) => _preferences!.setString(
    _mealsKey,
    jsonEncode(meals.map((meal) => meal.toJson()).toList()),
  );

  Future<void> clearProfile() => _preferences!.remove(_profileKey);
}
