part of 'user_workspace_screen.dart';

class _EducationArticle {
  const _EducationArticle({
    required this.title,
    required this.summary,
    required this.category,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String summary;
  final String category;
  final String body;
  final IconData icon;
  final Color color;
}

const _educationArticles = [
  _EducationArticle(
    title: 'Add variety to your plate',
    summary: 'Try different colors and food groups when available.',
    category: 'Nutrition',
    body: 'A varied selection can make meals more interesting. Use the foods that fit your preferences, budget, and availability.',
    icon: Icons.palette_outlined,
    color: AppColors.teal,
  ),
  _EducationArticle(
    title: 'Keep water nearby',
    summary: 'A refillable bottle can help you remember water.',
    category: 'Hydration',
    body: 'Keeping water where you can see it may make it easier to log your intake. Individual needs vary, so follow guidance from a qualified professional.',
    icon: Icons.water_drop_outlined,
    color: AppColors.blue,
  ),
  _EducationArticle(
    title: 'Build a regular meal routine',
    summary: 'Notice and plan around your own hunger cues.',
    category: 'Habits',
    body: 'A routine can make meal planning easier for some people. Adjust it to your schedule, appetite, and health needs.',
    icon: Icons.schedule_outlined,
    color: Color(0xFF8A68BE),
  ),
];

class _LearnTab extends StatefulWidget {
  const _LearnTab();

  @override
  State<_LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<_LearnTab> {
  String _query = '';
  String _category = 'All';
  final Set<String> _bookmarks = {};

  @override
  Widget build(BuildContext context) {
    final filteredArticles = _educationArticles.where((article) {
      final query = _query.trim().toLowerCase();
      final matchesQuery =
          article.title.toLowerCase().contains(query) ||
          article.summary.toLowerCase().contains(query);
      final matchesCategory = switch (_category) {
        'Saved' => _bookmarks.contains(article.title),
        'All' => true,
        _ => article.category == _category,
      };
      return matchesQuery && matchesCategory;
    }).toList();
    const categories = ['All', 'Nutrition', 'Hydration', 'Habits', 'Saved'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
      children: [
        const _PageHeading(
          title: 'Education & guidance',
          subtitle: 'Small ideas for balanced everyday choices',
        ),
        const SizedBox(height: 13),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'Search articles',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () => setState(() => _query = ''),
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: categories
                .map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        const _DemoNotice(
          text: 'Sample educational content only. References and personalized advice are not connected.',
        ),
        const SizedBox(height: 13),
        if (filteredArticles.isEmpty)
          const _EmptyCard(
            icon: Icons.bookmark_border,
            title: 'No articles found',
            subtitle: 'Try another topic or search term.',
          )
        else
          ...filteredArticles.map(
            (article) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _LearningCard(
                icon: article.icon,
                color: article.color,
                title: article.title,
                body: article.summary,
                tag: article.category.toUpperCase(),
                isBookmarked: _bookmarks.contains(article.title),
                onTap: () => _readArticle(article),
                onBookmark: () => setState(() {
                  _bookmarks.contains(article.title)
                      ? _bookmarks.remove(article.title)
                      : _bookmarks.add(article.title);
                }),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _readArticle(_EducationArticle article) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(article.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(article.body),
              const SizedBox(height: 14),
              Text('Related topic: ${article.category}'),
              const SizedBox(height: 8),
              const Text(
                'Sources are not provided for this sample article.',
                style: TextStyle(color: Color(0xFF78869A), fontSize: 10),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text('Sample articles do not include source links.'),
                ),
              );
            },
            child: const Text('View sources'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({
    required this.account,
    required this.meals,
    required this.waterMl,
    required this.goals,
    required this.onGoalsChanged,
    required this.onLogout,
  });

  final LocalAccount account;
  final List<MealRecord> meals;
  final int waterMl;
  final NutritionGoals goals;
  final ValueChanged<NutritionGoals> onGoalsChanged;
  final VoidCallback onLogout;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late String _displayName = widget.account.name;
  String _dietaryPreferences = 'No preferences selected';
  String _restrictions = 'None added';
  String _units = 'Metric';
  bool _mealReminders = false;
  bool _waterReminders = false;
  bool _shareUsage = false;

  Future<void> _editName() async {
    final controller = TextEditingController(text: _displayName);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profile'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.length >= 2) Navigator.pop(context, name);
            },
            child: const Text('Save profile'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) setState(() => _displayName = value);
  }

  Future<void> _editGoals() async {
    final updated = await showDialog<NutritionGoals>(
      context: context,
      builder: (_) => _NutritionGoalsDialog(goals: widget.goals),
    );
    if (updated != null) widget.onGoalsChanged(updated);
  }

  Future<void> _editDietaryPreferences() async {
    const choices = ['Vegetarian', 'Vegan', 'Pescatarian', 'No preference'];
    final selected = _dietaryPreferences == 'No preferences selected'
        ? <String>{}
        : _dietaryPreferences.split(', ').toSet();
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          title: const Text('Dietary preferences'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: choices
                .map(
                  (choice) => CheckboxListTile(
                    value: selected.contains(choice),
                    title: Text(choice),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => updateDialog(() {
                      value == true
                          ? selected.add(choice)
                          : selected.remove(choice);
                    }),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Save preferences'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(
        () => _dietaryPreferences = result.isEmpty
            ? 'No preferences selected'
            : result.join(', '),
      );
    }
  }

  Future<void> _editRestrictions() async {
    final controller = TextEditingController(
      text: _restrictions == 'None added' ? '' : _restrictions,
    );
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Food restrictions'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Allergies or restrictions',
            hintText: 'Comma-separated',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) {
      setState(() => _restrictions = value.isEmpty ? 'None added' : value);
    }
  }

  Future<void> _changeUnits() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Units'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Metric', label: Text('Metric')),
                ButtonSegment(value: 'Imperial', label: Text('Imperial')),
              ],
              selected: {_units},
              onSelectionChanged: (selection) =>
                  Navigator.pop(context, selection.first),
            ),
          ),
        ],
      ),
    );
    if (value != null) setState(() => _units = value);
  }

  Future<void> _previewDataDownload() async {
    final csv = [
      'name,category,calories,protein_g,carbs_g,fat_g',
      ...widget.meals.map(
        (meal) =>
            '${meal.name},${meal.category},${meal.calories},${meal.protein},${meal.carbs},${meal.fat}',
      ),
    ].join('\n');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My data preview'),
        content: SingleChildScrollView(
          child: Text('$csv\n\nWater total,${widget.waterMl} ml'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'Account deletion is not connected in this frontend preview. No local data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deletion is unavailable without backend support.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
      children: [
        const _PageHeading(
          title: 'My profile',
          subtitle: 'Your account and nutrition preferences',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF123B66), Color(0xFF146C78)],
            ),
            borderRadius: BorderRadius.circular(21),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 29,
                backgroundColor: const Color(0xFFDDF3EC),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.account.role,
                      style: const TextStyle(
                        color: Color(0xFFD3E4ED),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit profile',
                onPressed: _editName,
                color: Colors.white,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        _SimpleInfoCard(
          icon: Icons.email_outlined,
          title: 'Email',
          value: widget.account.email,
          color: AppColors.blue,
        ),
        const SizedBox(height: 10),
        _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Daily nutrition targets',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit nutrition targets',
                    onPressed: _editGoals,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                ],
              ),
              Text(
                '${widget.goals.calories} kcal · P ${widget.goals.protein} g · C ${widget.goals.carbs} g · F ${widget.goals.fat} g',
                style: const TextStyle(color: Color(0xFF53647A), fontSize: 11),
              ),
              const SizedBox(height: 5),
              const Text(
                'Session-only tracking target; not medical advice.',
                style: TextStyle(color: Color(0xFF8290A2), fontSize: 9),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB74B4B),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        _ProfileAction(
          icon: Icons.restaurant_menu_outlined,
          title: 'Dietary preferences',
          subtitle: _dietaryPreferences,
          onTap: _editDietaryPreferences,
        ),
        const SizedBox(height: 8),
        _ProfileAction(
          icon: Icons.warning_amber_outlined,
          title: 'Food restrictions',
          subtitle: _restrictions,
          onTap: _editRestrictions,
        ),
        const SizedBox(height: 8),
        _ProfileAction(
          icon: Icons.straighten_outlined,
          title: 'Units',
          subtitle: _units,
          onTap: _changeUnits,
        ),
        const SizedBox(height: 13),
        _WhiteCard(
          child: Column(
            children: [
              _ProfileToggle(
                title: 'Meal reminders',
                subtitle: 'Local preference preview',
                value: _mealReminders,
                onChanged: (value) => setState(() => _mealReminders = value),
              ),
              _ProfileToggle(
                title: 'Water reminders',
                subtitle: 'Scheduled delivery needs backend support',
                value: _waterReminders,
                onChanged: (value) => setState(() => _waterReminders = value),
              ),
              _ProfileToggle(
                title: 'Share usage data',
                subtitle: 'Privacy preview only',
                value: _shareUsage,
                onChanged: (value) => setState(() => _shareUsage = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _previewDataDownload,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Download my data · preview'),
        ),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.lock_reset_outlined),
          label: const Text('Change password · backend required'),
        ),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Verify email · backend required'),
        ),
        OutlinedButton.icon(
          onPressed: _confirmDeleteAccount,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete account'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB74B4B),
          ),
        ),
        const SizedBox(height: 8),
        const _DemoNotice(
          text: 'Profile edits and preferences are session-only in this preview. Password, email verification, scheduled notifications, and permanent account deletion need backend support.',
        ),
      ],
    );
  }
}

class _NutritionGoalsDialog extends StatefulWidget {
  const _NutritionGoalsDialog({required this.goals});

  final NutritionGoals goals;

  @override
  State<_NutritionGoalsDialog> createState() => _NutritionGoalsDialogState();
}

class _NutritionGoalsDialogState extends State<_NutritionGoalsDialog> {
  late final _calories = TextEditingController(
    text: widget.goals.calories.toString(),
  );
  late final _carbs = TextEditingController(
    text: widget.goals.carbs.toString(),
  );
  late final _protein = TextEditingController(
    text: widget.goals.protein.toString(),
  );
  late final _fat = TextEditingController(text: widget.goals.fat.toString());
  String? _error;

  @override
  void dispose() {
    _calories.dispose();
    _carbs.dispose();
    _protein.dispose();
    _fat.dispose();
    super.dispose();
  }

  void _save() {
    final values = [
      _calories,
      _carbs,
      _protein,
      _fat,
    ].map((controller) => int.tryParse(controller.text)).toList();
    if (values.any((value) => value == null || value <= 0)) {
      setState(() => _error = 'Enter a positive number for each target.');
      return;
    }
    Navigator.pop(
      context,
      NutritionGoals(
        calories: values[0]!,
        carbs: values[1]!,
        protein: values[2]!,
        fat: values[3]!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Daily nutrition targets'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final field in [
            ('Calories (kcal)', _calories),
            ('Carbohydrates (g)', _carbs),
            ('Protein (g)', _protein),
            ('Fat (g)', _fat),
          ]) ...[
            TextField(
              controller: field.$2,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: field.$1),
            ),
            const SizedBox(height: 8),
          ],
          if (_error != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFB74B4B), fontSize: 11),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save targets')),
    ],
  );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE6EDF1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.blue, size: 21),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF78869A),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF78869A)),
          ],
        ),
      ),
    ),
  );
}

class _ProfileToggle extends StatelessWidget {
  const _ProfileToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF78869A), fontSize: 10),
            ),
          ],
        ),
      ),
      Switch.adaptive(value: value, onChanged: onChanged),
    ],
  );
}
