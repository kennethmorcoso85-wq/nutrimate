import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../widgets/app_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
    children: [
      const Text(
        'Settings',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 27,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Workspace preferences and app information',
        style: TextStyle(color: Color(0xFF78869A), fontSize: 12),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.blue, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Preview settings · preferences shown here are not saved or applied.',
                style: TextStyle(
                  color: Color(0xFF365A83),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const _SettingsGroup(
        title: 'Workspace',
        children: [
          _SettingsRow(
            icon: Icons.business_outlined,
            title: 'Workspace information',
            subtitle: 'Workspace name and reporting period',
            trailing: 'Local workspace',
          ),
          _SettingsRow(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'Application display language',
            trailing: 'English',
          ),
          _SettingsRow(
            icon: Icons.calendar_month_outlined,
            title: 'Reporting period',
            subtitle: 'Default monitoring period',
            trailing: 'This week',
          ),
        ],
      ),
      const SizedBox(height: 12),
      const _SettingsGroup(
        title: 'Notifications',
        children: [
          _SettingsRow(
            icon: Icons.notifications_outlined,
            title: 'Meal log reminders',
            subtitle: 'Reminder preferences · preview only',
            toggle: true,
          ),
          _SettingsRow(
            icon: Icons.assignment_late_outlined,
            title: 'Follow-up alerts',
            subtitle: 'Review queue updates · preview only',
            toggle: true,
          ),
        ],
      ),
      const SizedBox(height: 12),
      _SettingsGroup(
        title: 'About',
        children: [
          const _SettingsRow(
            icon: Icons.favorite_outline,
            title: 'NutriMate',
            subtitle: 'Nutrition tracking and monitoring preview',
            trailing: 'v1.0.0',
          ),
          _SettingsRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy & data',
            subtitle: 'Local profile, meals, and goals stay on this device',
            onTap: () => _showPreviewMessage(context),
          ),
          _SettingsRow(
            icon: Icons.help_outline,
            title: 'Help & support',
            subtitle: 'Help content is not connected in this preview',
            onTap: () => _showPreviewMessage(context),
          ),
        ],
      ),
      const SizedBox(height: 13),
      const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Important',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'This UI preview is not connected to a shared account system and does not provide clinical assessment or medical advice. Use a qualified professional for nutrition guidance.',
              style: TextStyle(
                color: Color(0xFF65758C),
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  static void _showPreviewMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This option is visual-only in the preview.'),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.fromLTRB(15, 14, 8, 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        ...children,
      ],
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.toggle = false,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final bool toggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    onTap: onTap,
    leading: Icon(icon, color: AppColors.teal, size: 20),
    title: Text(
      title,
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: Color(0xFF8591A3), fontSize: 9),
    ),
    trailing: toggle
        ? const Switch(value: false, onChanged: null)
        : trailing != null
        ? Text(
            trailing!,
            style: const TextStyle(
              color: Color(0xFF78869A),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          )
        : const Icon(Icons.chevron_right, color: Color(0xFF9AA5B5), size: 18),
  );
}
