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

  factory _EducationArticle.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String;
    final iconAndColor = switch (category.toLowerCase()) {
      'hydration' => (Icons.water_drop_outlined, AppColors.blue),
      'habits' => (Icons.schedule_outlined, Color(0xFF8A68BE)),
      _ => (Icons.menu_book_outlined, AppColors.teal),
    };
    return _EducationArticle(
      title: json['title'] as String,
      summary: json['summary'] as String,
      category: category,
      body: json['body'] as String,
      icon: iconAndColor.$1,
      color: iconAndColor.$2,
    );
  }

  final String title;
  final String summary;
  final String category;
  final String body;
  final IconData icon;
  final Color color;
}

class _LearnTab extends StatefulWidget {
  const _LearnTab({
    required this.api,
    required this.account,
    required this.onAccountUpdated,
  });

  final NutriMateApi api;
  final LocalAccount account;
  final ValueChanged<LocalAccount> onAccountUpdated;

  @override
  State<_LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<_LearnTab> {
  String _query = '';
  String _category = 'All';
  final Set<String> _bookmarks = {};
  late Future<List<_EducationArticle>> _articles;

  @override
  void initState() {
    super.initState();
    _articles = _loadArticles();
    _bookmarks.addAll(
      (widget.account.preferences['bookmarked_articles'] as List? ?? const [])
          .whereType<String>(),
    );
  }

  Future<void> _toggleBookmark(_EducationArticle article) async {
    final bookmarks = {..._bookmarks};
    if (!bookmarks.add(article.title)) bookmarks.remove(article.title);
    try {
      final updated = await widget.api.updateProfile(
        name: widget.account.name,
        preferences: {
          ...widget.account.preferences,
          'bookmarked_articles': bookmarks.toList(),
        },
      );
      if (!mounted) return;
      setState(() {
        _bookmarks
          ..clear()
          ..addAll(bookmarks);
      });
      widget.onAccountUpdated(updated);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<List<_EducationArticle>> _loadArticles() async =>
      (await widget.api.articles()).map(_EducationArticle.fromJson).toList();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<_EducationArticle>>(
    future: _articles,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(snapshot.error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => setState(() => _articles = _loadArticles()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final allArticles = snapshot.data!;
      final categories = {
        'All',
        ...allArticles.map((article) => article.category),
        'Saved',
      }.toList();
      final filteredArticles = allArticles.where((article) {
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

      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
        children: [
          Row(
            children: [
              const Expanded(
                child: _PageHeading(
                  title: 'Education & guidance',
                  subtitle: 'Articles published by NutriMate administrators',
                ),
              ),
              IconButton(
                tooltip: 'Refresh articles',
                onPressed: () => setState(() => _articles = _loadArticles()),
                icon: const Icon(Icons.refresh),
              ),
            ],
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
          const SizedBox(height: 13),
          if (filteredArticles.isEmpty)
            const _EmptyCard(
              icon: Icons.bookmark_border,
              title: 'No published articles found',
              subtitle: 'Try another search or check back later.',
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
                  onBookmark: () => _toggleBookmark(article),
                ),
              ),
            ),
        ],
      );
    },
  );

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
            ],
          ),
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
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({
    required this.account,
    required this.api,
    required this.goals,
    required this.onGoalsChanged,
    required this.onLogout,
    required this.onAccountUpdated,
  });

  final LocalAccount account;
  final NutriMateApi api;
  final NutritionGoals goals;
  final ValueChanged<NutritionGoals> onGoalsChanged;
  final VoidCallback onLogout;
  final ValueChanged<LocalAccount> onAccountUpdated;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late String _displayName;
  late String _dietaryPreferences;
  late String _restrictions;
  late String _units;
  late bool _mealReminders;
  late bool _waterReminders;
  late bool _shareUsage;

  @override
  void initState() {
    super.initState();
    final preferences = widget.account.preferences;
    _displayName = widget.account.name;
    final dietary = preferences['dietary_preferences'];
    _dietaryPreferences =
        dietary is List && dietary.whereType<String>().isNotEmpty
        ? dietary.whereType<String>().join(', ')
        : 'No preferences selected';
    _restrictions = preferences['food_restrictions'] as String? ?? 'None added';
    _units = preferences['units'] as String? ?? 'Metric';
    _mealReminders = preferences['meal_reminders'] as bool? ?? false;
    _waterReminders = preferences['water_reminders'] as bool? ?? false;
    _shareUsage = preferences['share_usage'] as bool? ?? false;
  }

  Future<void> _savePreferences({
    String? name,
    List<String>? dietaryPreferences,
    String? restrictions,
    String? units,
    bool? mealReminders,
    bool? waterReminders,
    bool? shareUsage,
    NutritionGoals? goals,
  }) async {
    final preferences = <String, dynamic>{
      ...widget.account.preferences,
      'dietary_preferences':
          dietaryPreferences ??
          (_dietaryPreferences == 'No preferences selected'
              ? <String>[]
              : _dietaryPreferences.split(', ')),
      'food_restrictions': restrictions ?? _restrictions,
      'units': units ?? _units,
      'meal_reminders': mealReminders ?? _mealReminders,
      'water_reminders': waterReminders ?? _waterReminders,
      'share_usage': shareUsage ?? _shareUsage,
      'nutrition_goals': (goals ?? widget.goals).toJson(),
    };
    try {
      final updated = await widget.api.updateProfile(
        name: name ?? _displayName,
        preferences: preferences,
      );
      if (!mounted) return;
      setState(() {
        _displayName = updated.name;
        final savedDietary = updated.preferences['dietary_preferences'];
        _dietaryPreferences =
            savedDietary is List && savedDietary.whereType<String>().isNotEmpty
            ? savedDietary.whereType<String>().join(', ')
            : 'No preferences selected';
        _restrictions =
            updated.preferences['food_restrictions'] as String? ?? 'None added';
        _units = updated.preferences['units'] as String? ?? 'Metric';
        _mealReminders =
            updated.preferences['meal_reminders'] as bool? ?? false;
        _waterReminders =
            updated.preferences['water_reminders'] as bool? ?? false;
        _shareUsage = updated.preferences['share_usage'] as bool? ?? false;
      });
      widget.onAccountUpdated(updated);
      if (goals != null) widget.onGoalsChanged(goals);
      _message('Profile settings saved to your account.');
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

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
    if (value != null) await _savePreferences(name: value);
  }

  Future<void> _editGoals() async {
    final updated = await showDialog<NutritionGoals>(
      context: context,
      builder: (_) => _NutritionGoalsDialog(goals: widget.goals),
    );
    if (updated != null) await _savePreferences(goals: updated);
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
      await _savePreferences(dietaryPreferences: result.toList());
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
      await _savePreferences(
        restrictions: value.isEmpty ? 'None added' : value,
      );
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
    if (value != null) await _savePreferences(units: value);
  }

  Future<void> _exportData() async {
    try {
      final export = await widget.api.exportMyData();
      final account = export['account'] as Map<String, dynamic>;
      final meals = export['meals'] as List<dynamic>;
      final water = export['water'] as List<dynamic>;
      final waterEntries = export['water_entries'] as List<dynamic>;
      final measurements = export['measurements'] as List<dynamic>;
      final document = pw.Document();
      document.addPage(
        pw.MultiPage(
          build: (_) => [
            pw.Text(
              'NutriMate account export',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Name: ${account['name']}'),
            pw.Text('Email: ${account['email']}'),
            pw.SizedBox(height: 14),
            pw.Text(
              'Meal records (${meals.length})',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            ...meals.map((entry) {
              final meal = entry as Map<String, dynamic>;
              return pw.Text(
                '${meal['created_at']} · ${meal['name']} · ${meal['calories']} kcal · ${meal['category']}',
              );
            }),
            pw.SizedBox(height: 14),
            pw.Text(
              'Daily water records (${water.length})',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            ...water.map((entry) {
              final day = entry as Map<String, dynamic>;
              return pw.Text('${day['date']} · ${day['amount_ml']} ml');
            }),
            pw.SizedBox(height: 14),
            pw.Text(
              'Water entries (${waterEntries.length})',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            ...waterEntries.map((entry) {
              final item = entry as Map<String, dynamic>;
              return pw.Text(
                '${item['recorded_at']} · ${item['amount_ml']} ml',
              );
            }),
            pw.SizedBox(height: 14),
            pw.Text(
              'Body measurements (${measurements.length})',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            ...measurements.map((entry) {
              final item = entry as Map<String, dynamic>;
              return pw.Text(
                '${item['measured_at']} · ${item['weight_kg']} kg · ${item['height_cm'] ?? 'Height not recorded'} cm',
              );
            }),
          ],
        ),
      );
      await Printing.sharePdf(
        bytes: await document.save(),
        filename: 'nutrimate-account-data.pdf',
      );
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _changePassword() async {
    final values = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (values == null) return;
    try {
      await widget.api.changePassword(
        currentPassword: values.$1,
        newPassword: values.$2,
      );
      if (mounted) _message('Password changed successfully.');
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _verifyEmail() async {
    try {
      await widget.api.requestEmailVerification();
      if (!mounted || widget.account.emailVerified) return;
      final code = await showDialog<String>(
        context: context,
        builder: (_) => const _EmailCodeDialog(),
      );
      if (code == null) return;
      final updated = await widget.api.confirmEmailVerification(code);
      if (!mounted) return;
      widget.onAccountUpdated(updated);
      _message('Email address verified.');
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _ConfirmAccountDeletionDialog(),
    );
    if (password == null) return;
    try {
      await widget.api.deleteAccount(password);
      widget.onLogout();
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
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
                'Saved to your account; nutrition targets are not medical advice.',
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
                subtitle: 'Reminder preference saved to your account',
                value: _mealReminders,
                onChanged: (value) => _savePreferences(mealReminders: value),
              ),
              _ProfileToggle(
                title: 'Water reminders',
                subtitle: 'Reminder preference saved to your account',
                value: _waterReminders,
                onChanged: (value) => _savePreferences(waterReminders: value),
              ),
              _ProfileToggle(
                title: 'Share usage data',
                subtitle: 'Privacy preference saved to your account',
                value: _shareUsage,
                onChanged: (value) => _savePreferences(shareUsage: value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _exportData,
          icon: const Icon(Icons.download_outlined),
          label: const Text('View my data export'),
        ),
        OutlinedButton.icon(
          onPressed: _changePassword,
          icon: const Icon(Icons.lock_reset_outlined),
          label: const Text('Change password'),
        ),
        OutlinedButton.icon(
          onPressed: widget.account.emailVerified ? null : _verifyEmail,
          icon: const Icon(Icons.verified_outlined),
          label: Text(
            widget.account.emailVerified ? 'Email verified' : 'Verify email',
          ),
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
          text: 'Profile settings are saved to your account. Email verification and password recovery require the backend email service; reminders are stored as preferences and do not send push notifications.',
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

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _new = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Change password'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _current,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Current password'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _new,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_current.text.isEmpty || _new.text.length < 8) return;
          Navigator.pop(context, (_current.text, _new.text));
        },
        child: const Text('Update password'),
      ),
    ],
  );
}

class _EmailCodeDialog extends StatefulWidget {
  const _EmailCodeDialog();

  @override
  State<_EmailCodeDialog> createState() => _EmailCodeDialogState();
}

class _EmailCodeDialogState extends State<_EmailCodeDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Verify email'),
    content: TextField(
      controller: _code,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: const InputDecoration(
        labelText: '6-digit code',
        helperText: 'Check the email account used to sign up.',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!RegExp(r'^\d{6}$').hasMatch(_code.text)) return;
          Navigator.pop(context, _code.text);
        },
        child: const Text('Verify'),
      ),
    ],
  );
}

class _ConfirmAccountDeletionDialog extends StatefulWidget {
  const _ConfirmAccountDeletionDialog();

  @override
  State<_ConfirmAccountDeletionDialog> createState() =>
      _ConfirmAccountDeletionDialogState();
}

class _ConfirmAccountDeletionDialogState
    extends State<_ConfirmAccountDeletionDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Delete account permanently?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This permanently deletes your account, meal records, and water history.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Current password'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB74B4B)),
        onPressed: () {
          if (_password.text.isEmpty) return;
          Navigator.pop(context, _password.text);
        },
        child: const Text('Delete permanently'),
      ),
    ],
  );
}
