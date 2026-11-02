import 'package:flutter/material.dart';

import '../models/meal_entry.dart';
import '../models/nutrition_goals.dart';
import '../utils/app_colors.dart';
import '../utils/date_format_label.dart';
import '../widgets/app_card.dart';
import '../widgets/meal_tile.dart';
import '../widgets/section_title.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({
    required this.meals,
    required this.goals,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.readOnly = false,
    super.key,
  });

  final List<MealEntry> meals;
  final NutritionGoals goals;
  final VoidCallback onAdd;
  final ValueChanged<MealEntry> onEdit;
  final ValueChanged<MealEntry> onDelete;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final total = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    final remaining = goals.calories - total;
    final categories = [
      ('Breakfast', Icons.wb_sunny_outlined),
      ('Lunch', Icons.lunch_dining_outlined),
      ('Dinner', Icons.dinner_dining_outlined),
      ('Snack', Icons.cookie_outlined),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    readOnly ? 'My meal history' : 'Food diary',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    readOnly
                        ? 'Your own locally saved food log · read only'
                        : 'Build a clear picture of your daily meals',
                    style: TextStyle(color: Color(0xFF78869A), fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE6ECF2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormatLabel.shortDate(),
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        if (readOnly) ...[
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.blue, size: 17),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PERSONAL FOOD LOG · READ ONLY · stored on this device',
                    style: TextStyle(
                      color: Color(0xFF365A83),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _IntakeSummary(
          calories: total,
          goal: goals.calories,
          remaining: remaining,
          mealCount: meals.length,
        ),
        const SizedBox(height: 19),
        const SectionTitle('Meal categories'),
        const SizedBox(height: 10),
        SizedBox(
          height: 91,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, _) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final (label, icon) = categories[index];
              final count = meals
                  .where((meal) => meal.category == label)
                  .length;
              return Container(
                width: 86,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE7EDF2)),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: AppColors.teal, size: 21),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$count logged',
                      style: const TextStyle(
                        color: Color(0xFF8491A4),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 19),
        Row(
          children: [
            const Expanded(child: SectionTitle('Today’s entries')),
            Text(
              '${meals.length} ${meals.length == 1 ? 'item' : 'items'}',
              style: const TextStyle(
                color: Color(0xFF78869A),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (meals.isEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 27),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.no_food_outlined,
                    size: 30,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Nothing logged yet',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Add breakfast, lunch, dinner, or a snack to start your nutrition diary.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF78869A),
                    height: 1.4,
                    fontSize: 12,
                  ),
                ),
                if (!readOnly) ...[
                  const SizedBox(height: 15),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add your first meal'),
                  ),
                ],
              ],
            ),
          )
        else
          ...meals.map(
            (meal) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MealTile(
                meal: meal,
                onEdit: readOnly ? null : () => onEdit(meal),
                onDelete: readOnly ? null : () => onDelete(meal),
              ),
            ),
          ),
        if (meals.isNotEmpty && !readOnly) ...[
          const SizedBox(height: 5),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add another meal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                side: const BorderSide(color: Color(0xFFB9DDD4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _IntakeSummary extends StatelessWidget {
  const _IntakeSummary({
    required this.calories,
    required this.goal,
    required this.remaining,
    required this.mealCount,
  });

  final int calories;
  final int goal;
  final int remaining;
  final int mealCount;

  @override
  Widget build(BuildContext context) {
    final progress = (calories / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF123B66), Color(0xFF146C78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TODAY’S INTAKE',
                  style: TextStyle(
                    color: Color(0xFFC3E5E6),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$mealCount ${mealCount == 1 ? 'MEAL' : 'MEALS'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$calories',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6, bottom: 3),
                child: Text(
                  'kcal logged',
                  style: TextStyle(color: Color(0xFFD3E4ED), fontSize: 12),
                ),
              ),
              const Spacer(),
              Text(
                'Goal $goal kcal',
                style: const TextStyle(color: Color(0xFFD3E4ED), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: .2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF8EE0C4),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            remaining >= 0
                ? '$remaining kcal remaining to your daily target'
                : '${remaining.abs()} kcal over your daily target',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
