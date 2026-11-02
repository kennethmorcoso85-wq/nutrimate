import 'package:flutter/material.dart';

import '../models/meal_entry.dart';
import '../models/nutrition_goals.dart';
import '../utils/app_colors.dart';
import '../utils/app_role.dart';
import '../utils/date_format_label.dart';
import '../widgets/app_card.dart';
import '../widgets/section_title.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({
    required this.meals,
    required this.goals,
    this.role = AppRole.user,
    super.key,
  });

  final List<MealEntry> meals;
  final NutritionGoals goals;
  final AppRole role;

  @override
  Widget build(BuildContext context) {
    if (!role.isUser) return _buildPreviewReport();
    final now = DateTime.now();
    final days = List<DateTime>.generate(
      7,
      (index) => DateUtils.dateOnly(now).subtract(Duration(days: 6 - index)),
    );
    final totals = days
        .map(
          (day) => meals
              .where((meal) => DateUtils.isSameDay(meal.createdAt, day))
              .fold<int>(0, (sum, meal) => sum + meal.calories),
        )
        .toList();
    final today = totals.last;
    final average = totals.fold<int>(0, (sum, item) => sum + item) ~/ 7;
    final weekTotal = totals.fold<int>(0, (sum, item) => sum + item);
    final loggedDays = totals.where((value) => value > 0).length;
    final onTargetDays = totals
        .where(
          (value) =>
              value > 0 &&
              value >= goals.calories * .8 &&
              value <= goals.calories * 1.2,
        )
        .length;
    final weekStart = days.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        const Text(
          'My nutrition report',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Personal trends from your locally saved food log',
          style: TextStyle(color: Color(0xFF78869A), fontSize: 12),
        ),
        const SizedBox(height: 16),
        _WeekSummary(
          average: average,
          weekTotal: weekTotal,
          start: weekStart,
          end: days.last,
          loggedDays: loggedDays,
        ),
        const SizedBox(height: 13),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle('Daily calories'),
                        SizedBox(height: 4),
                        Text(
                          'Logged intake vs your daily goal',
                          style: TextStyle(
                            color: Color(0xFF7D8BA0),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6F2),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Text(
                      '7 DAYS',
                      style: TextStyle(
                        color: AppColors.teal,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .7,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 21),
              SizedBox(
                height: 164,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(days.length, (index) {
                    final value = totals[index];
                    final height = value == 0
                        ? 5.0
                        : (value / (goals.calories * 1.3) * 108).clamp(
                            8.0,
                            108.0,
                          );
                    final isToday = index == days.length - 1;
                    final hasData = value > 0;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 18,
                            child: FittedBox(
                              child: Text(
                                hasData ? value.toString() : '–',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isToday
                                      ? AppColors.navy
                                      : const Color(0xFF8996A8),
                                  fontWeight: isToday
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 22,
                            height: height,
                            decoration: BoxDecoration(
                              color: hasData
                                  ? isToday
                                        ? AppColors.teal
                                        : const Color(0xFF8AC8BD)
                                  : const Color(0xFFE8EEF2),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormatLabel.weekday(days[index]),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isToday
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isToday
                                  ? AppColors.navy
                                  : const Color(0xFF75839A),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Calories logged',
                    style: TextStyle(color: Color(0xFF75839A), fontSize: 10),
                  ),
                  const Spacer(),
                  Text(
                    'Goal ${goals.calories} kcal / day',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Expanded(
              child: _ReportStatCard(
                icon: Icons.today_outlined,
                label: 'TODAY',
                value: '$today',
                unit: 'kcal',
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ReportStatCard(
                icon: Icons.flag_outlined,
                label: 'ON TARGET',
                value: '$onTargetDays / $loggedDays',
                unit: 'logged days',
                color: AppColors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: AppColors.blue,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle('About your report'),
                    SizedBox(height: 5),
                    Text(
                      'Only recorded meals are included. Days without entries are not estimated. Use trends as a guide—not as a diagnosis.',
                      style: TextStyle(
                        color: Color(0xFF65758C),
                        height: 1.4,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'For personalized nutrition guidance, speak with a qualified health professional.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8491A4), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildPreviewReport() {
    final (
      title,
      subtitle,
      firstLabel,
      secondLabel,
      firstValue,
      secondValue,
    ) = (
      'Workspace reports',
      'Administrative overview · sample content',
      'SAMPLE USERS',
      'REPORT CYCLES',
      '32',
      '04',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
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
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5E3),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Row(
            children: [
              Icon(Icons.visibility_outlined, color: Color(0xFFAA7417)),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'PREVIEW · figures and reporting scope are fictional sample data',
                  style: TextStyle(
                    color: Color(0xFF805D1A),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF123B66), Color(0xFF146C78)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'REPORTING PERIOD · THIS WEEK',
                style: TextStyle(
                  color: Color(0xFFC3E5E6),
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 17),
              Row(
                children: [
                  Expanded(
                    child: _HeroReportValue(
                      label: firstLabel,
                      value: firstValue,
                      unit: 'sample',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 42,
                    color: Colors.white.withValues(alpha: .2),
                  ),
                  Expanded(
                    child: _HeroReportValue(
                      label: secondLabel,
                      value: secondValue,
                      unit: 'sample',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Report overview'),
              const SizedBox(height: 8),
              Text(
                'Workspace and administrative examples only. This report does not create or edit official nutrition assessments.',
                style: const TextStyle(
                  color: Color(0xFF65758C),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: null,
                  child: Text('Export report · preview only'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekSummary extends StatelessWidget {
  const _WeekSummary({
    required this.average,
    required this.weekTotal,
    required this.start,
    required this.end,
    required this.loggedDays,
  });

  final int average;
  final int weekTotal;
  final DateTime start;
  final DateTime end;
  final int loggedDays;

  @override
  Widget build(BuildContext context) => Container(
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
                'WEEKLY OVERVIEW',
                style: TextStyle(
                  color: Color(0xFFC3E5E6),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ),
            Text(
              '${DateFormatLabel.shortDateFor(start)} – ${DateFormatLabel.shortDateFor(end)}',
              style: const TextStyle(color: Color(0xFFD3E4ED), fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _HeroReportValue(
                label: 'DAILY AVERAGE',
                value: '$average',
                unit: 'kcal',
              ),
            ),
            Container(
              width: 1,
              height: 42,
              color: Colors.white.withValues(alpha: .2),
            ),
            Expanded(
              child: _HeroReportValue(
                label: 'WEEKLY TOTAL',
                value: '$weekTotal',
                unit: 'kcal',
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            const Icon(
              Icons.event_available_outlined,
              size: 15,
              color: Color(0xFF9CE4C9),
            ),
            const SizedBox(width: 6),
            Text(
              '$loggedDays of 7 days with food entries',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _HeroReportValue extends StatelessWidget {
  const _HeroReportValue({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFC3D7E2),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(color: Color(0xFFD3E4ED), fontSize: 10),
        ),
      ],
    ),
  );
}

class _ReportStatCard extends StatelessWidget {
  const _ReportStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(color: Color(0xFF78869A), fontSize: 10),
        ),
      ],
    ),
  );
}
