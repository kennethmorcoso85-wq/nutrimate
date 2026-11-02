part of 'user_workspace_screen.dart';

class _NutritionHero extends StatelessWidget {
  const _NutritionHero({
    required this.calories,
    required this.goals,
    required this.mealCount,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
  final int calories;
  final NutritionGoals goals;
  final int mealCount;
  final int protein;
  final int carbs;
  final int fat;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE1EAF3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Today’s calories',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$mealCount ${mealCount == 1 ? 'meal' : 'meals'} logged',
              style: const TextStyle(color: Color(0xFF7A899D), fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: (calories / goals.calories).clamp(0.0, 1.0),
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFFE5EDF7),
                      color: const Color(0xFF1684E8),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$calories',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 21,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'of ${goals.calories} kcal',
                        style: const TextStyle(
                          color: Color(0xFF7A899D),
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  _DashboardMacroBar(
                    label: 'Protein',
                    value: protein,
                    goal: goals.protein,
                    color: const Color(0xFF14B895),
                  ),
                  const SizedBox(height: 10),
                  _DashboardMacroBar(
                    label: 'Carbs',
                    value: carbs,
                    goal: goals.carbs,
                    color: const Color(0xFFF1A337),
                  ),
                  const SizedBox(height: 10),
                  _DashboardMacroBar(
                    label: 'Fat',
                    value: fat,
                    goal: goals.fat,
                    color: const Color(0xFF9B68D7),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          calories >= goals.calories
              ? '${calories - goals.calories} kcal over target'
              : '${goals.calories - calories} kcal remaining',
          style: const TextStyle(
            color: Color(0xFF53647A),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _DashboardMacroBar extends StatelessWidget {
  const _DashboardMacroBar({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });
  final String label;
  final int value;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$value g',
            style: const TextStyle(
              color: Color(0xFF6F8096),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: (value / goal).clamp(0.0, 1.0),
          minHeight: 6,
          color: color,
          backgroundColor: const Color(0xFFEDF1F6),
        ),
      ),
    ],
  );
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({
    required this.waterMl,
    required this.onAddWater,
    required this.onOpenHistory,
  });
  final int waterMl;
  final ValueChanged<int> onAddWater;
  final VoidCallback onOpenHistory;

  Future<void> _addCustomAmount(BuildContext context) async {
    final controller = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Custom water amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount in ml'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Save water'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount != null) onAddWater(amount);
  }

  @override
  Widget build(BuildContext context) => _WhiteCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.water_drop_outlined, color: AppColors.blue, size: 20),
        const SizedBox(height: 7),
        const Text(
          'Water tracker',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '$waterMl ml',
          style: const TextStyle(
            color: AppColors.blue,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: double.infinity,
          height: 32,
          child: OutlinedButton(
            onPressed: () => onAddWater(250),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.blue,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('+ 250 ml', style: TextStyle(fontSize: 10)),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => onAddWater(500),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('+ 500 ml', style: TextStyle(fontSize: 9)),
              ),
            ),
            IconButton(
              tooltip: 'Custom water amount',
              onPressed: () => _addCustomAmount(context),
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined, size: 16),
            ),
            IconButton(
              tooltip: 'Water history',
              onPressed: onOpenHistory,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.history, size: 16),
            ),
          ],
        ),
      ],
    ),
  );
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.add_circle_outline, color: AppColors.teal, size: 20),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(color: Color(0xFF8491A4), fontSize: 9),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.arrow_forward, size: 16, color: AppColors.teal),
          ),
        ],
      ),
    ),
  );
}

class _TodayPill extends StatelessWidget {
  const _TodayPill({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xFFE6ECF2)),
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
                '${months[date.month - 1]} ${date.day}',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, size: 15, color: AppColors.navy),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklySummary extends StatelessWidget {
  const _WeeklySummary({
    required this.meals,
    required this.selectedDate,
    required this.onTap,
  });

  final List<MealRecord> meals;
  final DateTime selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateUtils.dateOnly(selectedDate)
        .subtract(Duration(days: selectedDate.weekday - 1));
    final dailyCalories = List<int>.generate(7, (index) {
      final day = firstDay.add(Duration(days: index));
      return meals
          .where((meal) => DateUtils.isSameDay(meal.createdAt, day))
          .fold<int>(0, (total, meal) => total + meal.calories);
    });
    final total = dailyCalories.fold<int>(0, (sum, amount) => sum + amount);
    final maximum = dailyCalories.fold<int>(
      1,
      (current, amount) => amount > current ? amount : current,
    );
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE1EAF3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Weekly summary',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$total kcal · estimates',
                    style: const TextStyle(
                      color: Color(0xFF78869A),
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF78869A),
                    size: 17,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              SizedBox(
                height: 62,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List<Widget>.generate(7, (index) {
                    final value = dailyCalories[index];
                    final barHeight = value == 0
                        ? 4.0
                        : 8 + 36 * value / maximum;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 13,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: value == 0
                                  ? const Color(0xFFE5EDF7)
                                  : const Color(0xFF1684E8),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            weekdays[index],
                            style: const TextStyle(
                              color: Color(0xFF8290A2),
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationPreviewTile extends StatelessWidget {
  const _NotificationPreviewTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.isRead,
    required this.onMarkRead,
    required this.onDismiss,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool isRead;
  final VoidCallback onMarkRead;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F8FC),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          color: isRead ? const Color(0xFF8290A2) : const Color(0xFF1684E8),
          size: 19,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isRead)
                    const Text(
                      'READ',
                      style: TextStyle(
                        color: Color(0xFF8290A2),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(color: Color(0xFF78869A), fontSize: 10),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: isRead ? 'Mark as unread' : 'Mark as read',
          onPressed: onMarkRead,
          visualDensity: VisualDensity.compact,
          icon: Icon(
            isRead ? Icons.mark_email_unread_outlined : Icons.done,
            size: 17,
          ),
        ),
        IconButton(
          tooltip: 'Dismiss notification',
          onPressed: onDismiss,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close, size: 17),
        ),
      ],
    ),
  );
}
