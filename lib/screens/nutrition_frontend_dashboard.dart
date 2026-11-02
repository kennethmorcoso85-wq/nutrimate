import 'package:flutter/material.dart';

class NutritionFrontendDashboard extends StatelessWidget {
  const NutritionFrontendDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D6C7A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            final padding = isWide ? 20.0 : 12.0;

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Column(
                  children: [
                    _TopBar(isWide: isWide),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'USER JOURNEY',
                      subtitle: 'The user tracks their own nutrition, records meals, monitors progress, and gets guidance.',
                      accent: const Color(0xFF17C4A1),
                      isWide: isWide,
                    ),
                    const SizedBox(height: 10),
                    _FeatureGrid(
                      columns: isWide ? 6 : 2,
                      items: _userFeatures,
                      cardColor: const Color(0xFFEAF7F4),
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(
                      title: 'ADMIN JOURNEY',
                      subtitle: 'The admin manages accounts, maintains the food database, and ensures the system runs smoothly.',
                      accent: const Color(0xFF109CF8),
                      isWide: isWide,
                    ),
                    const SizedBox(height: 10),
                    _FeatureGrid(
                      columns: isWide ? 6 : 2,
                      items: _adminFeatures,
                      cardColor: const Color(0xFFEAF3FF),
                    ),
                    const SizedBox(height: 20),
                    _BottomInfoRow(isWide: isWide),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 18 : 12,
        vertical: isWide ? 12 : 10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0B6774),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.eco_rounded, color: Colors.white, size: isWide ? 32 : 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nutrition Monitoring Application',
              style: TextStyle(
                fontSize: isWide ? 28 : 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          if (isWide)
            Row(
              children: [
                const Text(
                  'Better Food  •  Better Health  •  A Healthier You',
                  style: TextStyle(
                    color: Color(0xFFBEEAF4),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 18),
                _PlatformChip(
                  icon: Icons.desktop_windows_outlined,
                  label: 'Web App (React)',
                ),
                const SizedBox(width: 10),
                _PlatformChip(
                  icon: Icons.phone_iphone_rounded,
                  label: 'Mobile App (Flutter)',
                ),
                const SizedBox(width: 10),
                _PlatformChip(
                  icon: Icons.storage_rounded,
                  label: 'Database (MySQL)',
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PlatformChip extends StatelessWidget {
  const _PlatformChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.isWide,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 18 : 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: isWide ? 24 : 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D3F4C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF276677)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({
    required this.columns,
    required this.items,
    required this.cardColor,
  });

  final int columns;
  final List<_FeatureItem> items;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _FeatureCard(item: item, cardColor: cardColor);
        },
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.item, required this.cardColor});

  final _FeatureItem item;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: Colors.white, size: 16),
              ),
              const Spacer(),
              if (item.tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.tag!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: item.color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF083B4E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF4D6A73),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minHeight: 42),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.tags
                  .map(
                    (chip) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        chip,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Color(0xFF2F5D68),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomInfoRow extends StatelessWidget {
  const _BottomInfoRow({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _InfoBlock(
        title: 'APPLICATION NAVIGATION',
        subtitle: 'Welcome, Admin',
        accent: const Color(0xFF2AC7B7),
        body: const ['Dashboard', 'Meals', 'Reports', 'Articles', 'Settings'],
      ),
      _InfoBlock(
        title: 'SYSTEM ARCHITECTURE',
        subtitle: 'Web + Mobile + Data Layer',
        accent: const Color(0xFF109CF8),
        body: const [
          'React Web App',
          'Flutter Mobile App',
          'Django API',
          'MySQL Database',
          'Authentication',
        ],
      ),
      _InfoBlock(
        title: 'KEY USER INTERACTIONS',
        subtitle: 'Core workflow',
        accent: const Color(0xFFE9B84A),
        body: const [
          'Login and secure dashboard',
          'Log meals and progress',
          'Admin manages content and users',
          'Reports update after actions',
        ],
      ),
    ];

    return SizedBox(
      width: double.infinity,
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cards
                  .map(
                    (card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: card,
                      ),
                    ),
                  )
                  .toList(),
            )
          : Column(
              children: cards
                  .map(
                    (card) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: card,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.body,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<String> body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFCFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0D3F4C),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF477383), fontSize: 11),
          ),
          const SizedBox(height: 12),
          ...body.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        color: Color(0xFF153C4C),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.title,
    required this.value,
    required this.tags,
    required this.icon,
    required this.color,
    this.tag,
  });

  final String title;
  final String value;
  final List<String> tags;
  final IconData icon;
  final Color color;
  final String? tag;
}

final List<_FeatureItem> _userFeatures = [
  _FeatureItem(
    title: 'Splash / Welcome',
    value: 'Welcome back! Login to continue.',
    tags: ['Profile', 'Access'],
    icon: Icons.favorite_border,
    color: const Color(0xFF18B28B),
    tag: 'Start',
  ),
  _FeatureItem(
    title: 'Home Dashboard',
    value: 'Daily totals, meal status, hydration, and trends.',
    tags: ['Overview', 'Summary'],
    icon: Icons.dashboard_rounded,
    color: const Color(0xFF33A7F9),
  ),
  _FeatureItem(
    title: 'Profile Settings',
    value: 'Dietary preferences, goals, allergies, privacy.',
    tags: ['Goals', 'Settings'],
    icon: Icons.person_outline,
    color: const Color(0xFF7A7AEF),
  ),
  _FeatureItem(
    title: 'Food Search',
    value: 'Search foods, categories, allergens, and serving sizes.',
    tags: ['Food', 'Search'],
    icon: Icons.search_rounded,
    color: const Color(0xFF20BFA3),
  ),
  _FeatureItem(
    title: 'Add Meal',
    value: 'Log breakfast, lunch, dinner, and snacks with quantities.',
    tags: ['Meal', 'Log'],
    icon: Icons.restaurant_menu_rounded,
    color: const Color(0xFFF39A58),
  ),
  _FeatureItem(
    title: 'Nutrient Summary',
    value: 'Track protein, carbs, fats, calories, and totals.',
    tags: ['Nutrition', 'Calories'],
    icon: Icons.bar_chart_rounded,
    color: const Color(0xFF3FC39F),
  ),
  _FeatureItem(
    title: 'Water Tracker',
    value: 'Capture hydration and daily water intake quickly.',
    tags: ['Hydration', 'Track'],
    icon: Icons.water_drop_rounded,
    color: const Color(0xFF53B7FF),
  ),
  _FeatureItem(
    title: 'Progress',
    value: 'Track measurements and patterns over time.',
    tags: ['Weight', 'History'],
    icon: Icons.trending_up_rounded,
    color: const Color(0xFF6BC1A8),
  ),
  _FeatureItem(
    title: 'Education & Guidance',
    value: 'Access nutrition articles and meal advice.',
    tags: ['Tips', 'Learn'],
    icon: Icons.menu_book_rounded,
    color: const Color(0xFF8D6FF6),
  ),
  _FeatureItem(
    title: 'Notifications',
    value: 'Reminder settings for meals and water intake.',
    tags: ['Alerts', 'Reminders'],
    icon: Icons.notifications_none_rounded,
    color: const Color(0xFFEB8D4C),
  ),
  _FeatureItem(
    title: 'Reports & Export',
    value: 'Daily, weekly, and monthly report views and exports.',
    tags: ['Reports', 'CSV'],
    icon: Icons.download_rounded,
    color: const Color(0xFF26A29A),
  ),
];

final List<_FeatureItem> _adminFeatures = [
  _FeatureItem(
    title: 'Admin Dashboard',
    value: 'View account activity, stats, and system health.',
    tags: ['Stats', 'Overview'],
    icon: Icons.space_dashboard_rounded,
    color: const Color(0xFF2AA4AF),
  ),
  _FeatureItem(
    title: 'User Management',
    value: 'Search, filter, activate, and audit user accounts.',
    tags: ['Users', 'Roles'],
    icon: Icons.group_rounded,
    color: const Color(0xFF4E7BE3),
  ),
  _FeatureItem(
    title: 'Food Database',
    value: 'Maintain food composition and serve verified data.',
    tags: ['Foods', 'Data'],
    icon: Icons.dataset_rounded,
    color: const Color(0xFF39B784),
  ),
  _FeatureItem(
    title: 'Food Categories',
    value: 'Organize categories, units, nutrients, and rules.',
    tags: ['Categories', 'Units'],
    icon: Icons.category_rounded,
    color: const Color(0xFF53A3FF),
  ),
  _FeatureItem(
    title: 'Nutrition Content',
    value: 'Create, preview, and publish nutrition guidance.',
    tags: ['Articles', 'Content'],
    icon: Icons.article_rounded,
    color: const Color(0xFF7A6DE5),
  ),
  _FeatureItem(
    title: 'Recommendation Rules',
    value: 'Publish educational suggestions and rule versions.',
    tags: ['Rules', 'Suggestions'],
    icon: Icons.psychology_alt_rounded,
    color: const Color(0xFFF3A64B),
  ),
  _FeatureItem(
    title: 'Reports & Analytics',
    value: 'Track usage, completeness, and system trends.',
    tags: ['Analytics', 'Reports'],
    icon: Icons.auto_graph_rounded,
    color: const Color(0xFF4FB3F8),
  ),
  _FeatureItem(
    title: 'Notifications',
    value: 'Send announcements and monitor delivery status.',
    tags: ['Alerts', 'Messages'],
    icon: Icons.campaign_rounded,
    color: const Color(0xFFEB7C8E),
  ),
  _FeatureItem(
    title: 'Audit Logs',
    value: 'Review changes, security events, and privacy actions.',
    tags: ['Audit', 'Security'],
    icon: Icons.fact_check_rounded,
    color: const Color(0xFF6ABF82),
  ),
  _FeatureItem(
    title: 'Settings',
    value: 'System configuration, retention and safety controls.',
    tags: ['Config', 'Security'],
    icon: Icons.settings_outlined,
    color: const Color(0xFF8F8F8F),
  ),
  _FeatureItem(
    title: 'System Status',
    value: 'Health checks, backups, and secure monitoring.',
    tags: ['Backup', 'Health'],
    icon: Icons.monitor_heart_rounded,
    color: const Color(0xFF3EAF97),
  ),
];
