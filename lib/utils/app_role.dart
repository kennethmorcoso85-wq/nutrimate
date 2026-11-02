import 'package:flutter/material.dart';

enum AppRole { user, admin }

enum AppRoute {
  home,
  meals,
  monitoring,
  ownRecord,
  reports,
  notifications,
  users,
  activity,
  profile,
  settings,
}

class AppDestination {
  const AppDestination(this.route, this.label, this.icon, this.selectedIcon);

  final AppRoute route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

extension AppRoleDetails on AppRole {
  String get label => switch (this) {
    AppRole.user => 'User',
    AppRole.admin => 'Admin',
  };

  bool get isUser => this == AppRole.user;

  List<AppDestination> get destinations => switch (this) {
    AppRole.user => const [
      AppDestination(
        AppRoute.home,
        'Home',
        Icons.space_dashboard_outlined,
        Icons.space_dashboard,
      ),
      AppDestination(
        AppRoute.meals,
        'Meals',
        Icons.restaurant_outlined,
        Icons.restaurant,
      ),
      AppDestination(
        AppRoute.ownRecord,
        'My record',
        Icons.assignment_ind_outlined,
        Icons.assignment_ind,
      ),
      AppDestination(
        AppRoute.reports,
        'My report',
        Icons.bar_chart_outlined,
        Icons.bar_chart,
      ),
      AppDestination(
        AppRoute.notifications,
        'Alerts',
        Icons.notifications_none_outlined,
        Icons.notifications,
      ),
      AppDestination(
        AppRoute.profile,
        'Profile',
        Icons.person_outline,
        Icons.person,
      ),
    ],
    AppRole.admin => const [
      AppDestination(
        AppRoute.home,
        'Home',
        Icons.space_dashboard_outlined,
        Icons.space_dashboard,
      ),
      AppDestination(
        AppRoute.users,
        'Users',
        Icons.manage_accounts_outlined,
        Icons.manage_accounts,
      ),
      AppDestination(
        AppRoute.monitoring,
        'Monitoring',
        Icons.monitor_heart_outlined,
        Icons.monitor_heart,
      ),
      AppDestination(
        AppRoute.reports,
        'Reports',
        Icons.bar_chart_outlined,
        Icons.bar_chart,
      ),
      AppDestination(
        AppRoute.notifications,
        'Alerts',
        Icons.notifications_none_outlined,
        Icons.notifications,
      ),
      AppDestination(
        AppRoute.activity,
        'Activity',
        Icons.history_outlined,
        Icons.history,
      ),
      AppDestination(
        AppRoute.settings,
        'Settings',
        Icons.settings_outlined,
        Icons.settings,
      ),
      AppDestination(
        AppRoute.profile,
        'Profile',
        Icons.person_outline,
        Icons.person,
      ),
    ],
  };

  bool allows(AppRoute route) =>
      destinations.any((destination) => destination.route == route);

  static AppRole fromLabel(String? label) {
    final normalized = label?.trim().toLowerCase();
    return normalized == 'admin' || normalized == 'administrator'
        ? AppRole.admin
        : AppRole.user;
  }
}
