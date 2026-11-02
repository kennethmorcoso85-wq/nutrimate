import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_role.dart';

class RoleNotificationsScreen extends StatelessWidget {
  const RoleNotificationsScreen({required this.role, super.key});

  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final content = role.isUser
        ? (
            'My notifications',
            'Personal reminders for your food log and profile',
            <(IconData, Color, String, String, String)>[
              (
                Icons.restaurant_outlined,
                AppColors.teal,
                'Keep your food log up to date',
                'A sample reminder to review your own meal history.',
                'Reminder',
              ),
              (
                Icons.insights_outlined,
                AppColors.blue,
                'Your weekly report is ready',
                'Personal report preview based only on meals saved on this device.',
                'New',
              ),
            ],
          )
        : (
            'Workspace notifications',
            'Administrative activity and system reminders · preview',
            <(IconData, Color, String, String, String)>[
              (
                Icons.manage_accounts_outlined,
                AppColors.blue,
                'Sample account review',
                'Static user examples are available in user management.',
                'Info',
              ),
              (
                Icons.history_outlined,
                AppColors.teal,
                'Workspace activity preview',
                'Fictional events are displayed in the activity log.',
                'New',
              ),
            ],
          );
    final (title, subtitle, alerts) = content;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 27,
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
              Icon(
                Icons.visibility_outlined,
                color: Color(0xFFAA7417),
                size: 18,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'PREVIEW · notifications are fictional samples; no messages are delivered.',
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
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'Recent',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${alerts.length}',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ...alerts.map(
          (alert) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _RoleNotificationCard(
              icon: alert.$1,
              color: alert.$2,
              title: alert.$3,
              description: alert.$4,
              status: alert.$5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE6ECF2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.notifications_off_outlined, color: AppColors.blue),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'No live alerts, delivery preferences, external messages, or real notification history are connected.',
                  style: TextStyle(
                    color: Color(0xFF65758C),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleNotificationCard extends StatelessWidget {
  const _RoleNotificationCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.status,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE6ECF2)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
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
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF718096),
                  height: 1.4,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PREVIEW · $status'.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
