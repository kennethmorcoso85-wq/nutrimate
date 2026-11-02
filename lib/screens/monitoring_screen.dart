import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/section_title.dart';

class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
    children: [
      const Text(
        'Nutrition monitoring',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 27,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Sample meal logging activity across user accounts',
        style: TextStyle(color: Color(0xFF78869A), fontSize: 12),
      ),
      const SizedBox(height: 16),
      const _PreviewPanel(),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth > 660
              ? (constraints.maxWidth - 24) / 3
              : (constraints.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MonitorStat(
                width: width,
                label: 'Meal entries',
                value: '186',
                detail: 'Today',
                color: AppColors.teal,
                icon: Icons.restaurant_outlined,
              ),
              _MonitorStat(
                width: width,
                label: 'Active users',
                value: '42',
                detail: 'This week · sample',
                color: const Color(0xFFD18B19),
                icon: Icons.pending_actions_outlined,
              ),
              _MonitorStat(
                width: width,
                label: 'Follow-up notes',
                value: '08',
                detail: 'Sample queue',
                color: const Color(0xFF755EB7),
                icon: Icons.assignment_outlined,
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 19),
      const SectionTitle('User logging activity'),
      const SizedBox(height: 10),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: const [
            _UserActivityRow(
              name: 'User account A',
              recorded: '3 meal entries today',
              status: 'Active',
              ratio: .72,
              color: Color(0xFFD18B19),
            ),
            Divider(height: 1, indent: 15, endIndent: 15),
            _UserActivityRow(
              name: 'User account B',
              recorded: '2 meal entries today',
              status: 'Active',
              ratio: 1,
              color: AppColors.teal,
            ),
            Divider(height: 1, indent: 15, endIndent: 15),
            _UserActivityRow(
              name: 'User account C',
              recorded: 'No entries today',
              status: 'Review',
              ratio: .48,
              color: Color(0xFFD18B19),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Review checklist'),
            const SizedBox(height: 12),
            const _ChecklistItem(
              label: 'Meal logs received',
              detail: 'Sample status · 23 of 25 users',
              icon: Icons.check_circle_outline,
              color: AppColors.teal,
            ),
            const Divider(height: 20),
            const _ChecklistItem(
              label: 'Follow-up queue reviewed',
              detail: 'Sample status · 8 notes pending',
              icon: Icons.schedule_outlined,
              color: Color(0xFFD18B19),
            ),
            const Divider(height: 20),
            const _ChecklistItem(
              label: 'Weekly summary prepared',
              detail: 'Sample status · updated today',
              icon: Icons.description_outlined,
              color: AppColors.blue,
            ),
            const SizedBox(height: 13),
            const SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: null,
                child: Text('Export monitoring summary · preview only'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'User activity figures are fictional sample data. This screen does not show real accounts or assess anyone’s health.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF8491A4), fontSize: 10),
      ),
    ],
  );
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF123B66), Color(0xFF146C78)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      children: [
        Icon(Icons.visibility_outlined, color: Color(0xFFA7E0D0), size: 23),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monitoring workspace · preview',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Examples show logging workflow only—not clinical findings.',
                style: TextStyle(
                  color: Color(0xFFD3E4ED),
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MonitorStat extends StatelessWidget {
  const _MonitorStat({
    required this.width,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
    required this.icon,
  });
  final double width;
  final String label;
  final String value;
  final String detail;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(color: Color(0xFF8591A3), fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _UserActivityRow extends StatelessWidget {
  const _UserActivityRow({
    required this.name,
    required this.recorded,
    required this.status,
    required this.ratio,
    required this.color,
  });
  final String name;
  final String recorded;
  final String status;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$recorded · sample',
                    style: const TextStyle(
                      color: Color(0xFF8591A3),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            _TinyStatus(label: status, color: color),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: const Color(0xFFF0F3F6),
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
  });
  final String label;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              detail,
              style: const TextStyle(color: Color(0xFF8591A3), fontSize: 9),
            ),
          ],
        ),
      ),
      const Icon(Icons.chevron_right, color: Color(0xFF9AA5B5), size: 17),
    ],
  );
}

class _TinyStatus extends StatelessWidget {
  const _TinyStatus({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700),
    ),
  );
}
