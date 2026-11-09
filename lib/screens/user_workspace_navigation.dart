part of 'user_workspace_screen.dart';

class _UserDesktopSidebar extends StatelessWidget {
  const _UserDesktopSidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _items = [
    (Icons.home_outlined, 'Dashboard'),
    (Icons.restaurant_outlined, 'Meals'),
    (Icons.insights_outlined, 'Progress'),
    (Icons.menu_book_outlined, 'Learn'),
    (Icons.person_outline, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: 224,
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 0, 24),
          child: Text(
            'YOUR WORKSPACE',
            style: TextStyle(
              color: Color(0xFF8090A6),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        for (var index = 0; index < _items.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: _UserSidebarItem(
              icon: _items[index].$1,
              label: _items[index].$2,
              selected: selectedIndex == index,
              onTap: () => onDestinationSelected(index),
            ),
          ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.favorite_outline, color: Color(0xFF1684E8), size: 18),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Small steps, healthier days.',
                  style: TextStyle(
                    color: Color(0xFF24466D),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WaterLogEntry {
  _WaterLogEntry({String? id, required this.amount, DateTime? recordedAt})
    : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      recordedAt = recordedAt ?? DateTime.now();

  factory _WaterLogEntry.fromJson(Map<String, dynamic> json) => _WaterLogEntry(
    id: '${json['id']}',
    amount: json['amount_ml'] as int,
    recordedAt: DateTime.parse(json['recorded_at'] as String),
  );

  final String id;
  final int amount;
  final DateTime recordedAt;
}

class _UserSidebarItem extends StatelessWidget {
  const _UserSidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFE7F1FF) : Colors.transparent,
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: selected
                  ? const Color(0xFF117CE0)
                  : const Color(0xFF6D7C91),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF155FA5)
                    : const Color(0xFF53647A),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.account,
    required this.goals,
    required this.meals,
    required this.allMeals,
    required this.waterMl,
    required this.selectedDate,
    required this.onSelectDate,
    required this.onAddMeal,
    required this.onGoToMeals,
    required this.onGoToProgress,
    required this.onAddWater,
  });

  final LocalAccount account;
  final NutritionGoals goals;
  final List<MealRecord> meals;
  final List<MealRecord> allMeals;
  final int waterMl;
  final DateTime selectedDate;
  final VoidCallback onSelectDate;
  final VoidCallback onAddMeal;
  final VoidCallback onGoToMeals;
  final VoidCallback onGoToProgress;
  final ValueChanged<int> onAddWater;

  @override
  Widget build(BuildContext context) {
    final calories = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    final protein = meals.fold<int>(0, (sum, meal) => sum + meal.protein);
    final carbs = meals.fold<int>(0, (sum, meal) => sum + meal.carbs);
    final fat = meals.fold<int>(0, (sum, meal) => sum + meal.fat);
    final name = account.name.split(' ').first;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final desktop = constraints.maxWidth >= 1100;
        final overview = _NutritionHero(
          calories: calories,
          goals: goals,
          mealCount: meals.length,
          protein: protein,
          carbs: carbs,
          fat: fat,
        );
        final waterAndAction = Row(
          children: [
            Expanded(
              child: _WaterCard(
                waterMl: waterMl,
                onAddWater: onAddWater,
                onOpenHistory: onGoToProgress,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_circle_outline,
                label: 'Log a meal',
                caption: 'Add food to diary',
                onTap: onAddMeal,
              ),
            ),
          ],
        );
        final todayMeals = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: _SectionHeading('Today’s meals')),
                TextButton.icon(
                  onPressed: onGoToProgress,
                  icon: const Icon(Icons.insights_outlined, size: 15),
                  label: const Text('Progress'),
                ),
                TextButton(
                  onPressed: onGoToMeals,
                  child: const Text('View all'),
                ),
              ],
            ),
            if (meals.isEmpty)
              const _EmptyCard(
                icon: Icons.restaurant_menu,
                title: 'Your food diary is ready',
                subtitle: 'Log your first meal to see your daily nutrition.',
              )
            else
              ...meals
                  .take(3)
                  .map(
                    (meal) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _MealCard(meal: meal),
                    ),
                  ),
          ],
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good day, $name!',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: desktop ? 31 : 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your daily nutrition at a glance',
                          style: TextStyle(
                            color: Color(0xFF78869A),
                            fontSize: desktop ? 14 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TodayPill(date: selectedDate, onTap: onSelectDate),
                ],
              ),
              const SizedBox(height: 18),
              if (desktop) ...[
                Row(
                  children: [
                    Expanded(
                      child: _DesktopDashboardMetric(
                        icon: Icons.local_fire_department_outlined,
                        title: 'Calories',
                        value: '$calories kcal',
                        detail: 'of ${goals.calories} kcal target',
                        color: const Color(0xFF1684E8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DesktopDashboardMetric(
                        icon: Icons.restaurant_outlined,
                        title: 'Meals logged',
                        value: '${meals.length}',
                        detail: 'for selected day',
                        color: const Color(0xFF14A889),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DesktopDashboardMetric(
                        icon: Icons.water_drop_outlined,
                        title: 'Water intake',
                        value: '$waterMl ml',
                        detail: 'local daily total',
                        color: const Color(0xFF5885E8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DesktopDashboardMetric(
                        icon: Icons.bolt_outlined,
                        title: 'Protein',
                        value: '$protein g',
                        detail: 'of ${goals.protein} g target',
                        color: const Color(0xFFD28A28),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          overview,
                          const SizedBox(height: 16),
                          todayMeals,
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          waterAndAction,
                          const SizedBox(height: 14),
                          _WeeklySummary(
                            meals: allMeals,
                            selectedDate: selectedDate,
                            onTap: onGoToProgress,
                          ),
                          const SizedBox(height: 14),
                          const _DemoNotice(
                            text: 'Nutrition values are estimates from the starter food catalog and are not medical advice.',
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                overview,
                const SizedBox(height: 13),
                waterAndAction,
                const SizedBox(height: 15),
                todayMeals,
                const SizedBox(height: 13),
                _WeeklySummary(
                  meals: allMeals,
                  selectedDate: selectedDate,
                  onTap: onGoToProgress,
                ),
                const SizedBox(height: 12),
                const _DemoNotice(
                  text: 'Nutrition values are estimates from the starter food catalog and are not medical advice.',
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DesktopDashboardMetric extends StatelessWidget {
  const _DesktopDashboardMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 116),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE1EAF3)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF65758C),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF8290A2), fontSize: 9),
        ),
      ],
    ),
  );
}
