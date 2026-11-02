import 'package:flutter/material.dart';

import '../models/nutrition_goals.dart';
import '../models/student_profile.dart';
import '../utils/app_colors.dart';
import '../utils/app_role.dart';
import '../widgets/app_card.dart';
import '../widgets/profile_line.dart';
import '../widgets/section_title.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.profile,
    required this.goals,
    required this.onEditProfile,
    required this.onEditGoals,
    required this.onSignOut,
    this.role = AppRole.user,
    super.key,
  });

  final StudentProfile profile;
  final NutritionGoals goals;
  final VoidCallback onEditProfile;
  final VoidCallback onEditGoals;
  final VoidCallback onSignOut;
  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final initial = profile.name.isEmpty ? 'U' : profile.name[0].toUpperCase();
    if (!role.isUser) {
      return _buildRoleProfile(initial);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        const Text(
          'My profile',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Your personal wellness information',
          style: TextStyle(color: Color(0xFF78869A), fontSize: 12),
        ),
        const SizedBox(height: 16),
        _ProfileHeader(
          initial: initial,
          name: profile.name,
          role: profile.role,
          onEdit: onEditProfile,
        ),
        const SizedBox(height: 13),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Personal details'),
              const SizedBox(height: 9),
              ProfileLine(
                icon: Icons.notes_outlined,
                label: 'About me',
                value: profile.grade.isEmpty ? 'Not set' : profile.grade,
              ),
              const Divider(height: 10),
              ProfileLine(
                icon: Icons.height,
                label: 'Height',
                value: '${profile.height.toStringAsFixed(0)} cm',
              ),
              const Divider(height: 10),
              ProfileLine(
                icon: Icons.monitor_weight_outlined,
                label: 'Weight',
                value: '${profile.weight.toStringAsFixed(1)} kg',
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: SectionTitle('Daily nutrition targets'),
                  ),
                  IconButton(
                    tooltip: 'Edit goals',
                    onPressed: onEditGoals,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.teal,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${goals.calories}',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 29,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'kcal per day',
                style: TextStyle(color: Color(0xFF78869A), fontSize: 11),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _GoalMacroChip(
                      label: 'Carbs',
                      value: goals.carbs,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GoalMacroChip(
                      label: 'Protein',
                      value: goals.protein,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GoalMacroChip(
                      label: 'Fat',
                      value: goals.fat,
                      color: const Color(0xFFF3A623),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 17,
                      color: Color(0xFF74849A),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nutrition goals are tracking estimates. Ask a qualified professional for personalized advice.',
                        style: TextStyle(
                          color: Color(0xFF65758C),
                          fontSize: 10,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6F2),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.teal,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const SectionTitle('Privacy & data'),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Your profile, goals, and food log are stored on this device. This prototype does not connect to a shared account system or cloud service.',
                style: TextStyle(
                  color: Color(0xFF65758C),
                  height: 1.45,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 7),
              TextButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout, size: 17),
                label: const Text('Sign out'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB74B4B),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleProfile(String initial) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
    children: [
      const Text(
        'My profile',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 25,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Local profile and role selection',
        style: TextStyle(color: Color(0xFF78869A), fontSize: 12),
      ),
      const SizedBox(height: 16),
      _ProfileHeader(
        initial: initial,
        name: profile.name,
        role: role.label,
        onEdit: onEditProfile,
      ),
      const SizedBox(height: 13),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Profile details'),
            const SizedBox(height: 9),
            ProfileLine(
              icon: Icons.person_outline,
              label: 'Name',
              value: profile.name,
            ),
            const Divider(height: 10),
            ProfileLine(
              icon: Icons.badge_outlined,
              label: 'Role preview',
              value: role.label,
            ),
            const Divider(height: 10),
            ProfileLine(
              icon: Icons.notes_outlined,
              label: 'About me',
              value: profile.grade.isEmpty ? 'Not set' : profile.grade,
            ),
          ],
        ),
      ),
      const SizedBox(height: 13),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Local preview'),
            const SizedBox(height: 8),
            const Text(
              'This profile and role are stored on this device. Role-based screen visibility is only a UI preview; there is no authentication, server, or actual authorization.',
              style: TextStyle(
                color: Color(0xFF65758C),
                height: 1.45,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 7),
            TextButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout, size: 17),
              label: const Text('Sign out'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB74B4B),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _GoalMacroChip extends StatelessWidget {
  const _GoalMacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value g',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initial,
    required this.name,
    required this.role,
    required this.onEdit,
  });

  final String initial;
  final String name;
  final String role;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF123B66), Color(0xFF146C78)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: .45),
              width: 1.5,
            ),
          ),
          child: CircleAvatar(
            radius: 29,
            backgroundColor: const Color(0xFFDDF3EC),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFD3E4ED),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Edit profile',
          onPressed: onEdit,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: .12),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
      ],
    ),
  );
}
