import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/local_account.dart';
import '../services/nutrimate_api.dart';
import '../utils/app_colors.dart';

part 'admin_workspace_resources.dart';

class AdminWorkspaceScreen extends StatefulWidget {
  const AdminWorkspaceScreen({
    required this.account,
    required this.api,
    required this.onLogout,
    super.key,
  });

  final LocalAccount account;
  final NutriMateApi api;
  final Future<void> Function() onLogout;

  @override
  State<AdminWorkspaceScreen> createState() => _AdminWorkspaceScreenState();
}

class _AdminWorkspaceScreenState extends State<AdminWorkspaceScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _AdminOverview(
        account: widget.account,
        api: widget.api,
        onNavigate: (index) => setState(() => _tab = index),
      ),
      _UserManagementTab(api: widget.api),
      _AdminFoodTab(api: widget.api),
      _AdminReportsTab(api: widget.api),
      _AdminSettingsTab(
        onLogout: widget.onLogout,
        onNavigate: (index) => setState(() => _tab = index),
      ),
      _AdminResourceTab(api: widget.api, resource: _AdminResource.articles),
      _AdminResourceTab(
        api: widget.api,
        resource: _AdminResource.recommendations,
      ),
      _AdminResourceTab(
        api: widget.api,
        resource: _AdminResource.announcements,
      ),
      _AdminAuditTab(api: widget.api),
      _AdminMoreTab(onNavigate: (index) => setState(() => _tab = index)),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppColors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 9),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NutriMate Admin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  'ADMIN WORKSPACE',
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 1,
                    color: Color(0xFF78869A),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 13),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFE8F0FF),
              child: Text(
                widget.account.initials,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1000) return pages[_tab];
            return Row(
              children: [
                _AdminDesktopSidebar(
                  selectedIndex: _tab,
                  onDestinationSelected: (index) =>
                      setState(() => _tab = index),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1360),
                      child: pages[_tab],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 1000
          ? null
          : NavigationBar(
              selectedIndex: _tab <= 3 ? _tab : 4,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.manage_accounts_outlined),
                  selectedIcon: Icon(Icons.manage_accounts),
                  label: 'Users',
                ),
                NavigationDestination(
                  icon: Icon(Icons.dataset_outlined),
                  selectedIcon: Icon(Icons.dataset),
                  label: 'Foods',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.more_horiz),
                  label: 'More',
                ),
              ],
              onDestinationSelected: (index) =>
                  setState(() => _tab = index == 4 ? 9 : index),
            ),
    );
  }
}

class _AdminDesktopSidebar extends StatelessWidget {
  const _AdminDesktopSidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _items = [
    (Icons.space_dashboard_outlined, 'Dashboard', 0),
    (Icons.manage_accounts_outlined, 'Users', 1),
    (Icons.dataset_outlined, 'Food & categories', 2),
    (Icons.menu_book_outlined, 'Nutrition content', 5),
    (Icons.rule_outlined, 'Recommendation rules', 6),
    (Icons.notifications_outlined, 'Notifications', 7),
    (Icons.bar_chart_outlined, 'Reports', 3),
    (Icons.history_outlined, 'Audit logs', 8),
    (Icons.settings_outlined, 'Settings', 4),
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: 226,
    color: const Color(0xFF102B50),
    padding: const EdgeInsets.fromLTRB(15, 22, 15, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 0, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NUTRIMATE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'ADMIN CONSOLE',
                style: TextStyle(
                  color: Color(0xFF9DB2CD),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        for (var index = 0; index < _items.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: _AdminSidebarItem(
              icon: _items[index].$1,
              label: _items[index].$2,
              selected: selectedIndex == _items[index].$3,
              onTap: () => onDestinationSelected(_items[index].$3),
            ),
          ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 0, 6),
          child: Text(
            'LOCAL WORKSPACE',
            style: TextStyle(
              color: Color(0xFF9DB2CD),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: .8,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AdminSidebarItem extends StatelessWidget {
  const _AdminSidebarItem({
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
    color: selected ? const Color(0xFF1684E8) : Colors.transparent,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : const Color(0xFFB8C8DB),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFD9E3EF),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AdminOverview extends StatefulWidget {
  const _AdminOverview({
    required this.account,
    required this.api,
    required this.onNavigate,
  });

  final LocalAccount account;
  final NutriMateApi api;
  final ValueChanged<int> onNavigate;

  @override
  State<_AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<_AdminOverview> {
  late Future<Map<String, dynamic>> _dashboard;

  @override
  void initState() {
    super.initState();
    _dashboard = widget.api.adminDashboard();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _dashboard,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _AdminLoadError(
          message: snapshot.error.toString(),
          onRetry: () =>
              setState(() => _dashboard = widget.api.adminDashboard()),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final stats = snapshot.data!;
      final metrics = [
        _AdminMetricData(
          'Registered accounts',
          '${stats['registered_accounts']}',
          Icons.groups_outlined,
          AppColors.blue,
        ),
        _AdminMetricData(
          'Active accounts',
          '${stats['active_accounts']}',
          Icons.verified_user_outlined,
          AppColors.teal,
        ),
        _AdminMetricData(
          'Meal records',
          '${stats['meal_records']}',
          Icons.restaurant_outlined,
          const Color(0xFF8A68BE),
        ),
        _AdminMetricData(
          'Food categories',
          '${stats['food_categories']}',
          Icons.restaurant_menu_outlined,
          const Color(0xFFE6A13A),
        ),
        _AdminMetricData(
          'Published foods',
          '${stats['published_food_records']}',
          Icons.public_outlined,
          const Color(0xFF42916D),
        ),
        _AdminMetricData(
          'Incomplete foods',
          '${stats['incomplete_food_records']}',
          Icons.warning_amber_outlined,
          const Color(0xFFB7791F),
        ),
        _AdminMetricData(
          'New today',
          '${stats['new_registrations_today']}',
          Icons.person_add_alt_1_outlined,
          const Color(0xFF8A68BE),
        ),
      ];
      final administration = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AdminSectionTitle('Administration'),
          const SizedBox(height: 9),
          _AdminAction(
            icon: Icons.manage_accounts_outlined,
            title: 'Manage accounts',
            subtitle: 'Create and manage server accounts',
            onTap: () => widget.onNavigate(1),
          ),
          const SizedBox(height: 8),
          _AdminAction(
            icon: Icons.dataset_outlined,
            title: 'Food catalog',
            subtitle: 'Review and publish shared food records',
            onTap: () => widget.onNavigate(2),
          ),
          const SizedBox(height: 8),
          _AdminAction(
            icon: Icons.analytics_outlined,
            title: 'Reports & analytics',
            subtitle: 'Review aggregate server statistics',
            onTap: () => widget.onNavigate(3),
          ),
          const SizedBox(height: 8),
          _AdminAction(
            icon: Icons.menu_book_outlined,
            title: 'Nutrition content',
            subtitle: 'Publish articles shown in the Learn section',
            onTap: () => widget.onNavigate(5),
          ),
          const SizedBox(height: 8),
          _AdminAction(
            icon: Icons.notifications_outlined,
            title: 'Announcements & audit logs',
            subtitle: 'Manage app announcements and review admin activity',
            onTap: () => widget.onNavigate(7),
          ),
        ],
      );
      final systemStatus = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE1EAF3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AdminSectionTitle('System status'),
            SizedBox(height: 12),
            _AdminStatusRow(
              icon: Icons.cloud_done_outlined,
              title: 'Backend API',
              value: 'Connected',
              color: AppColors.teal,
            ),
            Divider(height: 20),
            _AdminStatusRow(
              icon: Icons.storage_outlined,
              title: 'Data storage',
              value: 'SQLite server database',
              color: AppColors.blue,
            ),
            Divider(height: 20),
            _AdminStatusRow(
              icon: Icons.history_outlined,
              title: 'Audit activity',
              value: '${stats['audit_events']} events recorded',
              color: AppColors.teal,
            ),
          ],
        ),
      );

      return LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final metricCards = LayoutBuilder(
            builder: (context, metricConstraints) {
              final columns = metricConstraints.maxWidth > 620 ? 4 : 2;
              final width =
                  (metricConstraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: metrics
                    .map(
                      (metric) => SizedBox(
                        width: width,
                        child: _AdminMetricCard(data: metric),
                      ),
                    )
                    .toList(),
              );
            },
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
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
                            'Welcome, ${widget.account.name.split(' ').first}',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Workspace administration overview',
                            style: TextStyle(
                              color: Color(0xFF78869A),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh dashboard',
                      onPressed: () => setState(
                        () => _dashboard = widget.api.adminDashboard(),
                      ),
                      icon: const Icon(Icons.refresh),
                    ),
                    const _LocalTag(),
                  ],
                ),
                const SizedBox(height: 14),
                const _DemoNotice(
                  text: 'Dashboard statistics and account/food management use the Django REST API. Audit logging, content publishing, and notifications still need implementation.',
                ),
                const SizedBox(height: 16),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            metricCards,
                            const SizedBox(height: 22),
                            administration,
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            systemStatus,
                            const SizedBox(height: 14),
                            const _DemoNotice(
                              text: 'SQLite is configured for local development only. Use a production database and secure deployment settings before release.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  metricCards,
                  const SizedBox(height: 18),
                  administration,
                  const SizedBox(height: 16),
                  systemStatus,
                  const SizedBox(height: 13),
                  const _DemoNotice(
                    text: 'SQLite is configured for local development only. Use a production database and secure deployment settings before release.',
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

class _UserManagementTab extends StatefulWidget {
  const _UserManagementTab({required this.api});

  final NutriMateApi api;

  @override
  State<_UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<_UserManagementTab> {
  String _query = '';
  late Future<List<LocalAccount>> _accounts;

  @override
  void initState() {
    super.initState();
    _accounts = widget.api.adminUsers();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<LocalAccount>>(
    future: _accounts,
    builder: (context, snapshot) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
        children: [
          Row(
            children: [
              const Expanded(
                child: _AdminPageHeading(
                  title: 'User management',
                  subtitle: 'Manage accounts stored by the NutriMate API',
                ),
              ),
              IconButton.filled(
                tooltip: 'Add user',
                onPressed: _showCreateAccount,
                icon: const Icon(Icons.person_add_alt_1),
              ),
              IconButton(
                tooltip: 'Refresh users',
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _DemoNotice(
            text: 'Passwords are never shown in this list. Admin access is managed by the server and cannot be granted from public registration.',
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() {
              _query = value;
              _accounts = widget.api.adminUsers(search: value);
            }),
            decoration: InputDecoration(
              hintText: 'Search name or email',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () => setState(() {
                        _query = '';
                        _accounts = widget.api.adminUsers();
                      }),
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 13),
          if (snapshot.hasError)
            _AdminLoadError(
              message: snapshot.error.toString(),
              onRetry: _reload,
            )
          else if (!snapshot.hasData)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Row(
              children: [
                const Expanded(child: _AdminSectionTitle('Accounts')),
                Text(
                  '${snapshot.data!.length} accounts',
                  style: const TextStyle(
                    color: Color(0xFF78869A),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (snapshot.data!.isEmpty)
              const _AdminEmptyState(
                title: 'No matching accounts',
                message: 'Try another name or email.',
              )
            else
              ...snapshot.data!.map(
                (account) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _AccountCard(
                    account: account,
                    onToggle: account.isAdmin ? null : () => _toggle(account),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _showCreateAccount,
              icon: const Icon(Icons.add),
              label: const Text('Create user account'),
            ),
          ),
        ],
      );
    },
  );

  void _reload() =>
      setState(() => _accounts = widget.api.adminUsers(search: _query));

  Future<void> _showCreateAccount() async {
    final result = await showDialog<_NewAccountData>(
      context: context,
      builder: (_) => const _CreateAccountDialog(),
    );
    if (result == null) return;
    try {
      await widget.api.createAdminUser(
        name: result.name,
        email: result.email,
        password: result.password,
      );
      _reload();
      _message('User account created.');
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  Future<void> _toggle(LocalAccount account) async {
    if (account.active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Deactivate account?'),
          content: Text('Block sign-in for ${account.email}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      final updated = await widget.api.setAccountActive(
        account,
        active: !account.active,
      );
      _reload();
      _message(updated.active ? 'Account activated.' : 'Account deactivated.');
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

class _CreateAccountDialog extends StatefulWidget {
  const _CreateAccountDialog();

  @override
  State<_CreateAccountDialog> createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<_CreateAccountDialog> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create account'),
    content: Form(
      key: _key,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Enter a name'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) => value == null || !value.contains('@')
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) =>
                  (value?.length ?? 0) < 8 ? 'Use at least 8 characters' : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_key.currentState!.validate()) return;
          Navigator.pop(
            context,
            _NewAccountData(
              name: _name.text.trim(),
              email: _email.text.trim(),
              password: _password.text,
            ),
          );
        },
        child: const Text('Create'),
      ),
    ],
  );
}

class _NewAccountData {
  const _NewAccountData({
    required this.name,
    required this.email,
    required this.password,
  });
  final String name;
  final String email;
  final String password;
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.onToggle});
  final LocalAccount account;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE6EDF1)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: account.isAdmin
              ? const Color(0xFFE8F0FF)
              : const Color(0xFFE4F4EF),
          child: Text(
            account.initials,
            style: TextStyle(
              color: account.isAdmin ? AppColors.blue : AppColors.teal,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                account.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF78869A), fontSize: 9),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _TinyBadge(
                    label: account.isAdmin ? 'Admin' : 'User',
                    color: account.isAdmin ? AppColors.blue : AppColors.teal,
                  ),
                  const SizedBox(width: 5),
                  _TinyBadge(
                    label: account.active ? 'Active' : 'Inactive',
                    color: account.active
                        ? AppColors.teal
                        : const Color(0xFF9A6570),
                  ),
                ],
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => onToggle?.call(),
          itemBuilder: (_) => [
            if (onToggle != null)
              PopupMenuItem(
                value: 'toggle',
                child: Text(account.active ? 'Deactivate' : 'Activate'),
              ),
            if (onToggle == null)
              const PopupMenuItem(enabled: false, child: Text('Admin account')),
          ],
        ),
      ],
    ),
  );
}

class _AdminFoodTab extends StatefulWidget {
  const _AdminFoodTab({required this.api});

  final NutriMateApi api;

  @override
  State<_AdminFoodTab> createState() => _AdminFoodTabState();
}

class _AdminFoodTabState extends State<_AdminFoodTab> {
  late Future<void> _load;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _foods = [];
  String _search = '';
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load = _loadData();
  }

  Future<void> _loadData() async {
    final categories = await widget.api.categories();
    final foods = await widget.api.foods(search: _search);
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _foods = foods;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _load,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _AdminLoadError(
          message: snapshot.error.toString(),
          onRetry: () => setState(() => _load = _loadData()),
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      final activeCategories = _categories
          .where((category) => category['is_active'] == true)
          .toList();
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
        children: [
          Row(
            children: [
              const Expanded(
                child: _AdminPageHeading(
                  title: 'Food catalog',
                  subtitle: 'Manage server food records and categories',
                ),
              ),
              IconButton(
                tooltip: 'Refresh catalog',
                onPressed: () => setState(() => _load = _loadData()),
                icon: const Icon(Icons.refresh),
              ),
              IconButton.filled(
                tooltip: 'Add food',
                onPressed: activeCategories.isEmpty ? null : () => _editFood(),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _DemoNotice(
            text: 'Food records are stored in the backend. Confirm nutrient values, serving units, and data sources before publishing.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: _AdminSectionTitle('Categories')),
              TextButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add, size: 17),
                label: const Text('Add category'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_categories.isEmpty)
            const _AdminEmptyState(
              title: 'No food categories',
              message: 'Create a category before adding food records.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories
                  .map(
                    (category) => InputChip(
                      label: Text(category['name'] as String),
                      onDeleted: () => _toggleCategory(category),
                      deleteIcon: Icon(
                        category['is_active'] == true
                            ? Icons.archive_outlined
                            : Icons.restore,
                        size: 16,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: category['is_active'] == true
                            ? const Color(0xFFE4EBEF)
                            : const Color(0xFFE6C98E),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: _AdminSectionTitle('Food records')),
              Text(
                '${_foods.length} records',
                style: const TextStyle(fontSize: 10, color: Color(0xFF78869A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (value) => setState(() {
              _search = value;
              _load = _loadData();
            }),
            decoration: const InputDecoration(
              hintText: 'Search food',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          if (_foods.isEmpty)
            const _AdminEmptyState(
              title: 'No food records found',
              message: 'Add a food or change the search.',
            )
          else
            ..._foods.map(
              (food) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AdminFoodCard(
                  food: food,
                  onEdit: () => _editFood(food),
                  onDelete: () => _deleteFood(food),
                  onPublish: () => _changeFoodStatus(
                    food,
                    food['status'] == 'published' ? 'draft' : 'published',
                  ),
                  onArchive: () => _changeFoodStatus(food, 'archived'),
                ),
              ),
            ),
        ],
      );
    },
  );

  Future<void> _addCategory() async {
    _name.clear();
    final category = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add food category'),
        content: TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = _name.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (category != null) {
      try {
        await widget.api.createCategory(category);
        setState(() => _load = _loadData());
      } on ApiException catch (error) {
        _message(error.message);
      }
    }
  }

  Future<void> _toggleCategory(Map<String, dynamic> category) async {
    try {
      await widget.api.updateCategory(
        category['id'] as int,
        active: category['is_active'] != true,
      );
      setState(() => _load = _loadData());
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  Future<void> _editFood([Map<String, dynamic>? food]) async {
    final activeCategories = _categories
        .where((category) => category['is_active'] == true)
        .toList();
    final value = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          _FoodEditorDialog(categories: activeCategories, food: food),
    );
    if (value == null) return;
    try {
      await widget.api.saveFood(value, id: food?['id'] as int?);
      setState(() => _load = _loadData());
      _message('Food record saved.');
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  Future<void> _changeFoodStatus(
    Map<String, dynamic> food,
    String newStatus,
  ) async {
    try {
      final value = Map<String, dynamic>.from(food)
        ..remove('id')
        ..remove('category_name')
        ..remove('created_at')
        ..remove('updated_at')
        ..['status'] = newStatus;
      await widget.api.saveFood(value, id: food['id'] as int);
      setState(() => _load = _loadData());
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  Future<void> _deleteFood(Map<String, dynamic> food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete food record?'),
        content: Text('Delete ${food['name']} permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.deleteFood(food['id'] as int);
      setState(() => _load = _loadData());
      _message('Food record deleted.');
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

class _FoodEditorDialog extends StatefulWidget {
  const _FoodEditorDialog({required this.categories, this.food});

  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? food;

  @override
  State<_FoodEditorDialog> createState() => _FoodEditorDialogState();
}

class _FoodEditorDialogState extends State<_FoodEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.food?['name'] as String? ?? '',
  );
  late final _barcode = TextEditingController(
    text: widget.food?['barcode'] as String? ?? '',
  );
  late final _description = TextEditingController(
    text: widget.food?['description'] as String? ?? '',
  );
  late final _servingSize = TextEditingController(
    text: '${widget.food?['serving_size'] ?? '100'}',
  );
  late final _servingUnit = TextEditingController(
    text: widget.food?['serving_unit'] as String? ?? 'g',
  );
  late final _calories = TextEditingController(
    text: '${widget.food?['calories'] ?? '0'}',
  );
  late final _protein = TextEditingController(
    text: '${widget.food?['protein'] ?? '0'}',
  );
  late final _carbs = TextEditingController(
    text: '${widget.food?['carbs'] ?? '0'}',
  );
  late final _fat = TextEditingController(
    text: '${widget.food?['fat'] ?? '0'}',
  );
  late final _source = TextEditingController(
    text: widget.food?['data_source'] as String? ?? '',
  );
  late int _categoryId =
      widget.food?['category'] as int? ?? widget.categories.first['id'] as int;
  late String _status = widget.food?['status'] as String? ?? 'draft';

  @override
  void dispose() {
    _name.dispose();
    _barcode.dispose();
    _description.dispose();
    _servingSize.dispose();
    _servingUnit.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.food == null ? 'Add food' : 'Edit food'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_name, 'Food name'),
              _field(_barcode, 'Barcode', required: false),
              _field(_description, 'Description', required: false),
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category['id'] as int,
                        child: Text(category['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _categoryId = value ?? _categoryId),
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(_servingSize, 'Serving size', number: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_servingUnit, 'Serving unit')),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field(_calories, 'Calories', number: true)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(_protein, 'Protein (g)', number: true),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _field(_carbs, 'Carbs (g)', number: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_fat, 'Fat (g)', number: true)),
                ],
              ),
              _field(_source, 'Data source', required: false),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  DropdownMenuItem(
                    value: 'published',
                    child: Text('Published'),
                  ),
                  DropdownMenuItem(value: 'archived', child: Text('Archived')),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? 'draft'),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(context, {
            'name': _name.text.trim(),
            'barcode': _barcode.text.trim(),
            'description': _description.text.trim(),
            'category': _categoryId,
            'serving_size': _servingSize.text.trim(),
            'serving_unit': _servingUnit.text.trim(),
            'calories': int.parse(_calories.text),
            'protein': _protein.text.trim(),
            'carbs': _carbs.text.trim(),
            'fat': _fat.text.trim(),
            'data_source': _source.text.trim(),
            'status': _status,
          });
        },
        child: const Text('Save'),
      ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(top: 9),
    child: TextFormField(
      controller: controller,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return 'Required';
        if (number && text.isNotEmpty && num.tryParse(text) == null) {
          return 'Enter a number';
        }
        return null;
      },
    ),
  );
}

class _AdminFoodCard extends StatelessWidget {
  const _AdminFoodCard({
    required this.food,
    required this.onEdit,
    required this.onDelete,
    required this.onPublish,
    required this.onArchive,
  });

  final Map<String, dynamic> food;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPublish;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final status = food['status'] as String? ?? 'draft';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EDF1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu_outlined, color: AppColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food['name'] as String? ?? 'Food',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${food['calories']} kcal · P ${food['protein']}g · C ${food['carbs']}g · F ${food['fat']}g · ${food['category_name']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF8290A2), fontSize: 9),
                ),
                const SizedBox(height: 4),
                _TinyBadge(
                  label: status.toUpperCase(),
                  color: status == 'published'
                      ? AppColors.teal
                      : const Color(0xFF9A6570),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') onEdit();
              if (action == 'publish') onPublish();
              if (action == 'archive') onArchive();
              if (action == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'publish',
                child: Text(status == 'published' ? 'Unpublish' : 'Publish'),
              ),
              if (status != 'archived')
                const PopupMenuItem(value: 'archive', child: Text('Archive')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminMoreTab extends StatelessWidget {
  const _AdminMoreTab({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  static const _destinations = [
    (Icons.menu_book_outlined, 'Nutrition content', 'Backend connected', 5),
    (Icons.rule_outlined, 'Recommendation rules', 'Backend connected', 6),
    (Icons.notifications_outlined, 'Announcements', 'Backend connected', 7),
    (Icons.history_outlined, 'Audit logs', 'Backend connected', 8),
    (Icons.settings_outlined, 'Settings', 'Local settings', 4),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
    children: [
      const _AdminPageHeading(
        title: 'More admin tools',
        subtitle: 'Additional workspace sections and their current status',
      ),
      const SizedBox(height: 14),
      for (final destination in _destinations)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _AdminMoreDestination(
            icon: destination.$1,
            title: destination.$2,
            status: destination.$3,
            onTap: () => onNavigate(destination.$4),
          ),
        ),
      const SizedBox(height: 8),
    ],
  );
}

class _AdminMoreDestination extends StatelessWidget {
  const _AdminMoreDestination({
    required this.icon,
    required this.title,
    required this.status,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6EDF1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.teal, size: 20),
            const SizedBox(width: 11),
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
            Text(
              status,
              style: const TextStyle(color: Color(0xFF78869A), fontSize: 9),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right, color: Color(0xFF9AA5B5), size: 18),
          ],
        ),
      ),
    ),
  );
}

class _AdminReportsTab extends StatefulWidget {
  const _AdminReportsTab({required this.api});

  final NutriMateApi api;

  @override
  State<_AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<_AdminReportsTab> {
  late DateTime _start;
  late DateTime _end;
  late Future<Map<String, dynamic>> _report;

  @override
  void initState() {
    super.initState();
    _end = DateUtils.dateOnly(DateTime.now());
    _start = _end.subtract(const Duration(days: 29));
    _loadReport();
  }

  void _loadReport() {
    _report = widget.api.adminReport(start: _start, end: _end);
  }

  Future<void> _selectRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (range == null) return;
    setState(() {
      _start = DateUtils.dateOnly(range.start);
      _end = DateUtils.dateOnly(range.end);
      _loadReport();
    });
  }

  Future<void> _exportReport(Map<String, dynamic> report) async {
    final document = pw.Document();
    document.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'NutriMate aggregate report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Period: ${report['start']} to ${report['end']}'),
            pw.SizedBox(height: 14),
            pw.Text('New accounts: ${report['registered_accounts']}'),
            pw.Text('Meal records: ${report['meal_records']}'),
            pw.Text('Days with meal records: ${report['meal_days']}'),
            pw.Text('Active accounts: ${report['active_accounts']}'),
            pw.Text('Published foods: ${report['published_food_records']}'),
            pw.SizedBox(height: 12),
            pw.Text(
              'This report contains aggregate counts only; individual meal details are private.',
            ),
          ],
        ),
      ),
    );
    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'nutrimate-report-${report['start']}-${report['end']}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _report,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _AdminLoadError(
          message: snapshot.error.toString(),
          onRetry: () => setState(_loadReport),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final report = snapshot.data!;
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
        children: [
          Row(
            children: [
              const Expanded(
                child: _AdminPageHeading(
                  title: 'Reports & analytics',
                  subtitle: 'Aggregate server data; individual meal details stay private',
                ),
              ),
              IconButton(
                tooltip: 'Choose report dates',
                onPressed: _selectRange,
                icon: const Icon(Icons.date_range_outlined),
              ),
              IconButton(
                tooltip: 'Refresh report',
                onPressed: () => setState(_loadReport),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _AdminMetricCard(
            data: _AdminMetricData(
              'Registered accounts',
              '${report['registered_accounts']}',
              Icons.groups_outlined,
              AppColors.blue,
            ),
          ),
          const SizedBox(height: 9),
          _AdminMetricCard(
            data: _AdminMetricData(
              'Meal records',
              '${report['meal_records']}',
              Icons.restaurant_outlined,
              AppColors.teal,
            ),
          ),
          const SizedBox(height: 9),
          _AdminMetricCard(
            data: _AdminMetricData(
              'Published food records',
              '${report['published_food_records']}',
              Icons.public_outlined,
              const Color(0xFF42916D),
            ),
          ),
          const SizedBox(height: 13),
          const _AdminSectionTitle('Available summaries'),
          const SizedBox(height: 8),
          _ReportLink(
            icon: Icons.groups_outlined,
            title: 'User accounts summary',
            subtitle:
                '${report['active_accounts']} active accounts · ${report['registered_accounts']} new in period',
          ),
          _ReportLink(
            icon: Icons.insights_outlined,
            title: 'Meal logging activity',
            subtitle:
                '${report['meal_days']} days with meal records in selected period',
          ),
          const _ReportLink(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy scope',
            subtitle: 'Only aggregate meal counts are shown to admins; meal details remain private to each user.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _exportReport(report),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export aggregate report'),
          ),
        ],
      );
    },
  );
}

class _AdminSettingsTab extends StatelessWidget {
  const _AdminSettingsTab({required this.onLogout, required this.onNavigate});

  final Future<void> Function() onLogout;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
    children: [
      const _AdminPageHeading(
        title: 'Settings',
        subtitle: 'Manage backend-connected application data',
      ),
      const SizedBox(height: 15),
      const _DemoNotice(
        text: 'User profiles, nutrition preferences, meals, water totals, food catalog entries, articles, announcements, and admin events are stored by the backend.',
      ),
      const SizedBox(height: 8),
      _AdminSettingsRow(
        icon: Icons.category_outlined,
        title: 'Food categories',
        subtitle: 'Open the shared food catalog',
        onTap: () => onNavigate(2),
      ),
      const SizedBox(height: 8),
      _AdminSettingsRow(
        icon: Icons.notifications_outlined,
        title: 'Announcements',
        subtitle: 'Publish an in-app announcement for users',
        onTap: () => onNavigate(7),
      ),
      const SizedBox(height: 8),
      _AdminSettingsRow(
        icon: Icons.manage_accounts_outlined,
        title: 'User accounts',
        subtitle: 'Create or manage API accounts',
        onTap: () => onNavigate(1),
      ),
      const SizedBox(height: 16),
      const _DemoNotice(
        text: 'Announcements appear in the in-app notifications feed. This backend does not send push notifications.',
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: onLogout,
        icon: const Icon(Icons.logout),
        label: const Text('Sign out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB74B4B),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    ],
  );
}

class _AdminSettingsRow extends StatelessWidget {
  const _AdminSettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE6EDF1)),
        ),
        child: Row(
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
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8290A2),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9AA5B5), size: 19),
          ],
        ),
      ),
    ),
  );
}

class _ReportLink extends StatelessWidget {
  const _ReportLink({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 3),
    leading: Icon(icon, color: AppColors.teal),
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
      style: const TextStyle(color: Color(0xFF8290A2), fontSize: 9),
    ),
    trailing: const Icon(
      Icons.chevron_right,
      color: Color(0xFF9AA5B5),
      size: 19,
    ),
  );
}

class _AdminStatusRow extends StatelessWidget {
  const _AdminStatusRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 19),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Color(0xFF78869A),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _AdminMetricData {
  const _AdminMetricData(this.title, this.value, this.icon, this.color);
  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({required this.data});
  final _AdminMetricData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE6EDF1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(data.icon, color: data.color, size: 19),
        const SizedBox(height: 8),
        Text(
          data.value,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          data.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF78869A), fontSize: 9),
        ),
      ],
    ),
  );
}

class _AdminAction extends StatelessWidget {
  const _AdminAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE6EDF1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.teal, size: 21),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8290A2),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9AA5B5), size: 18),
          ],
        ),
      ),
    ),
  );
}

class _AdminSectionTitle extends StatelessWidget {
  const _AdminSectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: AppColors.navy,
      fontSize: 14,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _AdminPageHeading extends StatelessWidget {
  const _AdminPageHeading({required this.title, required this.subtitle});
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
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF78869A), fontSize: 11),
      ),
    ],
  );
}

class _AdminEmptyState extends StatelessWidget {
  const _AdminEmptyState({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE6EDF1)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.search_off_outlined,
          color: Color(0xFF8290A2),
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          message,
          style: const TextStyle(color: Color(0xFF78869A), fontSize: 10),
        ),
      ],
    ),
  );
}

class _AdminLoadError extends StatelessWidget {
  const _AdminLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 34, color: AppColors.blue),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700),
    ),
  );
}

class _LocalTag extends StatelessWidget {
  const _LocalTag();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3DD),
      borderRadius: BorderRadius.circular(9),
    ),
    child: const Text(
      'API CONNECTED',
      style: TextStyle(
        color: Color(0xFF93641B),
        fontSize: 8,
        letterSpacing: .5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6E7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: Color(0xFFAA7417), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF805D1A),
              fontSize: 9,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
