import 'package:flutter/material.dart';

import '../models/meal_entry.dart';
import '../utils/app_colors.dart';
import '../utils/date_format_label.dart';
import 'app_card.dart';

class MealTile extends StatelessWidget {
  const MealTile({
    required this.meal,
    this.compact = false,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final MealEntry meal;
  final bool compact;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final (icon, tint, background) = switch (meal.category) {
      'Breakfast' => (
        Icons.wb_sunny_outlined,
        const Color(0xFFB97816),
        const Color(0xFFFFF4E1),
      ),
      'Lunch' => (
        Icons.lunch_dining_outlined,
        AppColors.blue,
        const Color(0xFFEAF3FF),
      ),
      'Dinner' => (
        Icons.dinner_dining_outlined,
        const Color(0xFF7654B2),
        const Color(0xFFF2EDFA),
      ),
      _ => (Icons.cookie_outlined, AppColors.teal, const Color(0xFFEAF6F2)),
    };
    return AppCard(
      padding: EdgeInsets.all(compact ? 13 : 15),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${meal.category}  •  ${DateFormatLabel.time(meal.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF77869C),
                    fontSize: 11,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Carbs ${meal.carbs}g  ·  Protein ${meal.protein}g  ·  Fat ${meal.fat}g',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8895A7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F6F8),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${meal.calories}',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const Text(
                  'kcal',
                  style: TextStyle(color: Color(0xFF77869C), fontSize: 9),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            PopupMenuButton<String>(
              tooltip: 'Meal actions',
              onSelected: (value) {
                if (value == 'edit') onEdit!();
                if (value == 'delete') onDelete!();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
    );
  }
}
