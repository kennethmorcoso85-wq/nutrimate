import 'package:flutter/material.dart';

import '../models/meal_entry.dart';
import '../models/nutrition_goals.dart';
import '../models/student_profile.dart';
import '../utils/app_colors.dart';
import '../utils/app_role.dart';

class RoleDashboardScreen extends StatelessWidget {
  const RoleDashboardScreen({
    required this.role,
    required this.profile,
    required this.meals,
    required this.goals,
    required this.onNavigate,
    super.key,
  });

  final AppRole role;
  final StudentProfile profile;
  final List<MealEntry> meals;
  final NutritionGoals goals;
  final ValueChanged<AppRoute> onNavigate;

  @override
  Widget build(BuildContext context) {
    if (role.isUser) {
      return _UserHome(
        profile: profile,
        meals: meals,
        goals: goals,
        onNavigate: onNavigate,
      );
    }

    const data = _DashboardData(
      title: 'Administration',
      subtitle: 'Nutrition tracking and monitoring workspace',
      metricLabels: ['Sample users', 'Meal logs today', 'Monitoring'],
      metricValues: ['32', '186', 'Active'],
      actions: [
        _DashboardAction('User management', AppRoute.users),
        _DashboardAction('Nutrition monitoring', AppRoute.monitoring),
        _DashboardAction('Reports and activity', AppRoute.reports),
      ],
      note: 'Monitoring counts and workspace details are static sample content. User controls are not active.',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        _ScreenHeading(
          title: 'Hello, ${_firstName(profile.name)}',
          subtitle: data.title,
        ),
        const SizedBox(height: 5),
        Text(
          data.subtitle,
          style: const TextStyle(color: Color(0xFF78869A), fontSize: 13),
        ),
        const SizedBox(height: 18),
        const _PreviewBanner(),
        const SizedBox(height: 15),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 690 ? 3 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(
                data.metricLabels.length,
                (index) => SizedBox(
                  width: width,
                  child: _MetricCard(
                    label: data.metricLabels[index],
                    value: data.metricValues[index],
                    icon: switch (index) {
                      0 => Icons.groups_outlined,
                      1 => Icons.restaurant_outlined,
                      _ => Icons.fact_check_outlined,
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 19),
        const _SectionHeading('Quick access'),
        const SizedBox(height: 9),
        ...data.actions.map(
          (action) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _ActionCard(
              title: action.label,
              icon: _iconFor(action.route),
              onTap: () => onNavigate(action.route),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _InfoCard(data.note),
      ],
    );
  }
}

class _UserHome extends StatelessWidget {
  const _UserHome({
    required this.profile,
    required this.meals,
    required this.goals,
    required this.onNavigate,
  });

  final StudentProfile profile;
  final List<MealEntry> meals;
  final NutritionGoals goals;
  final ValueChanged<AppRoute> onNavigate;

  @override
  Widget build(BuildContext context) {
    final calories = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    final carbs = meals.fold<int>(0, (sum, meal) => sum + meal.carbs);
    final protein = meals.fold<int>(0, (sum, meal) => sum + meal.protein);
    final fat = meals.fold<int>(0, (sum, meal) => sum + meal.fat);
    final remaining = (goals.calories - calories).clamp(0, goals.calories);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ScreenHeading(
                title: 'Today',
                subtitle: 'Nutrition overview for ${_firstName(profile.name)}',
              ),
            ),
            IconButton(
              tooltip: 'Edit nutrition goals',
              onPressed: () => onNavigate(AppRoute.profile),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE8EDF2)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: goals.calories == 0
                            ? 0
                            : (calories / goals.calories).clamp(0.0, 1.0),
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        backgroundColor: const Color(0xFFE9EDF2),
                        color: const Color(0xFF0878E8),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$remaining',
                          style: const TextStyle(
                            color: Color(0xFF172333),
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'kcal left',
                          style: TextStyle(
                            color: Color(0xFF78869A),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CALORIES',
                      style: TextStyle(
                        color: Color(0xFF78869A),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$calories',
                      style: const TextStyle(
                        color: Color(0xFF172333),
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'of ${goals.calories} kcal goal',
                      style: const TextStyle(
                        color: Color(0xFF78869A),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${meals.length} ${meals.length == 1 ? 'meal' : 'meals'} logged today',
                      style: const TextStyle(
                        color: Color(0xFF344256),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 21),
        Container(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE8EDF2)),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeading('Macros'),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _MacroProgressCard(
                      label: 'Carbs',
                      amount: carbs,
                      goal: goals.carbs,
                      color: const Color(0xFF31B6A3),
                    ),
                  ),
                  Expanded(
                    child: _MacroProgressCard(
                      label: 'Fat',
                      amount: fat,
                      goal: goals.fat,
                      color: const Color(0xFF9B59B6),
                    ),
                  ),
                  Expanded(
                    child: _MacroProgressCard(
                      label: 'Protein',
                      amount: protein,
                      goal: goals.protein,
                      color: const Color(0xFFE7A52B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 21),
        Row(
          children: [
            const Expanded(child: _SectionHeading('Today’s food log')),
            TextButton(
              onPressed: () => onNavigate(AppRoute.meals),
              child: const Text('See diary'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (meals.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE8EDF2)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu, color: Color(0xFF0878E8)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No meals logged today',
                    style: TextStyle(
                      color: Color(0xFF344256),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Add a meal',
                  onPressed: () => onNavigate(AppRoute.meals),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          )
        else
          ...meals.take(3).map((meal) => _MealPreviewRow(meal: meal)),
        const SizedBox(height: 14),
        const _InfoCard(
          'Personal tracking is saved on this device. Nutrition goals are user-set estimates, not medical advice.',
        ),
      ],
    );
  }
}

class _MacroProgressCard extends StatelessWidget {
  const _MacroProgressCard({
    required this.label,
    required this.amount,
    required this.goal,
    required this.color,
  });

  final String label;
  final int amount;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color.withValues(alpha: .95),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: 68,
        height: 68,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: goal == 0 ? 0 : (amount / goal).clamp(0.0, 1.0),
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: const Color(0xFFE9EDF2),
                color: color,
              ),
            ),
            Text(
              '$amount',
              style: const TextStyle(
                color: Color(0xFF172333),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Goal ${goal}g',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF8994A3), fontSize: 9),
      ),
    ],
  );
}

class _MealPreviewRow extends StatelessWidget {
  const _MealPreviewRow({required this.meal});

  final MealEntry meal;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE8EDF2)),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.restaurant_outlined,
          color: Color(0xFF0878E8),
          size: 19,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF172333),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                meal.category,
                style: const TextStyle(color: Color(0xFF8994A3), fontSize: 10),
              ),
            ],
          ),
        ),
        Text(
          '${meal.calories} kcal',
          style: const TextStyle(
            color: Color(0xFF344256),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class PersonalRecordScreen extends StatelessWidget {
  const PersonalRecordScreen({
    required this.profile,
    required this.goals,
    required this.meals,
    super.key,
  });

  final StudentProfile profile;
  final NutritionGoals goals;
  final List<MealEntry> meals;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
    children: [
      const _ScreenHeading(
        title: 'My nutrition record',
        subtitle: 'Personal information saved in this local preview',
      ),
      const SizedBox(height: 15),
      const _PreviewBanner(),
      const SizedBox(height: 12),
      _RecordCard(
        title: 'My profile',
        icon: Icons.person_outline,
        lines: [
          'Name: ${profile.name}',
          'Grade / year: ${profile.grade.isEmpty ? 'Not set' : profile.grade}',
        ],
      ),
      const SizedBox(height: 10),
      _RecordCard(
        title: 'My food log',
        icon: Icons.restaurant_outlined,
        lines: [
          'Saved meal entries: ${meals.length}',
          'Daily tracking target: ${goals.calories} kcal',
        ],
      ),
      const SizedBox(height: 12),
      const _InfoCard(
        'This is your own locally stored profile and food log only. No peer records, BMI, nutrition classification, clinical interpretation, or diagnosis is shown.',
      ),
    ],
  );
}

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
    children: [
      const _ScreenHeading(
        title: 'User management',
        subtitle: 'Static account examples for the admin interface',
      ),
      const SizedBox(height: 15),
      const _PreviewBanner(),
      const SizedBox(height: 12),
      const _SectionHeading('Users · sample'),
      const SizedBox(height: 8),
      const _RecordCard(
        title: 'Jordan Lee',
        icon: Icons.person_outline,
        lines: ['Role: User', 'Status: Active · sample account'],
      ),
      const SizedBox(height: 8),
      const _RecordCard(
        title: 'Casey Rivera',
        icon: Icons.person_outline,
        lines: ['Role: User', 'Status: Active · sample account'],
      ),
      const SizedBox(height: 8),
      const _RecordCard(
        title: 'Morgan Patel',
        icon: Icons.person_outline,
        lines: ['Role: Admin', 'Status: Pending · sample account'],
      ),
      const SizedBox(height: 12),
      const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _DisabledAction(label: 'Add user'),
          _DisabledAction(label: 'Edit role'),
          _DisabledAction(label: 'Deactivate user'),
        ],
      ),
      const SizedBox(height: 13),
      const _InfoCard(
        'Sample accounts only. These disabled controls do not create accounts, change roles, grant access, or administer authentication.',
      ),
    ],
  );
}

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
    children: [
      const _ScreenHeading(
        title: 'Activity log',
        subtitle: 'Example workspace events · not a real audit trail',
      ),
      const SizedBox(height: 15),
      const _PreviewBanner(),
      const SizedBox(height: 12),
      const _RecordCard(
        title: 'Report preview opened',
        icon: Icons.bar_chart_outlined,
        lines: ['Today · 9:15 AM', 'Sample admin activity'],
      ),
      const SizedBox(height: 8),
      const _RecordCard(
        title: 'Meal schedule viewed',
        icon: Icons.schedule_outlined,
        lines: ['Today · 8:42 AM', 'Sample staff activity'],
      ),
      const SizedBox(height: 8),
      const _RecordCard(
        title: 'Nutrition monitoring viewed',
        icon: Icons.monitor_heart_outlined,
        lines: ['Yesterday · 3:20 PM', 'Sample admin activity'],
      ),
      const SizedBox(height: 13),
      const _InfoCard(
        'Events are hard-coded preview examples. There is no real audit logging, activity collection, or user tracking.',
      ),
    ],
  );
}

class _DashboardData {
  const _DashboardData({
    required this.title,
    required this.subtitle,
    required this.metricLabels,
    required this.metricValues,
    required this.actions,
    required this.note,
  });

  final String title;
  final String subtitle;
  final List<String> metricLabels;
  final List<String> metricValues;
  final List<_DashboardAction> actions;
  final String note;
}

class _DashboardAction {
  const _DashboardAction(this.label, this.route);
  final String label;
  final AppRoute route;
}

class _ScreenHeading extends StatelessWidget {
  const _ScreenHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF78869A), fontSize: 12),
      ),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.navy,
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF5E3),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFF4E3BF)),
    ),
    child: const Row(
      children: [
        Icon(Icons.visibility_outlined, color: Color(0xFFAA7417), size: 18),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'PREVIEW · sample names and figures only; no live account records',
            style: TextStyle(
              color: Color(0xFF805D1A),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE6ECF2)),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.teal, size: 19),
        const SizedBox(height: 11),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF78869A), fontSize: 10),
        ),
      ],
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE6ECF2)),
    ),
    child: ListTile(
      leading: Icon(icon, color: AppColors.teal),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    ),
  );
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.title,
    required this.icon,
    required this.lines,
  });
  final String title;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE6ECF2)),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.teal, size: 20),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              ...lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    line,
                    style: const TextStyle(
                      color: Color(0xFF65758C),
                      fontSize: 11,
                      height: 1.35,
                    ),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3FF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: AppColors.blue, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF365A83),
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DisabledAction extends StatelessWidget {
  const _DisabledAction({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) =>
      OutlinedButton(onPressed: null, child: Text(label));
}

IconData _iconFor(AppRoute route) => switch (route) {
  AppRoute.home => Icons.space_dashboard_outlined,
  AppRoute.meals => Icons.restaurant_outlined,
  AppRoute.monitoring => Icons.monitor_heart_outlined,
  AppRoute.ownRecord => Icons.assignment_ind_outlined,
  AppRoute.reports => Icons.bar_chart_outlined,
  AppRoute.notifications => Icons.notifications_none_outlined,
  AppRoute.users => Icons.manage_accounts_outlined,
  AppRoute.activity => Icons.history_outlined,
  AppRoute.profile => Icons.person_outline,
  AppRoute.settings => Icons.settings_outlined,
};

String _firstName(String name) =>
    name.trim().isEmpty ? 'there' : name.trim().split(RegExp(r'\s+')).first;
