import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/local_account.dart';
import '../models/meal_record.dart';
import '../models/nutrition_goals.dart';
import '../services/nutrimate_api.dart';
import '../utils/app_colors.dart';

part 'user_workspace_navigation.dart';
part 'user_workspace_meals.dart';
part 'user_workspace_progress.dart';
part 'user_workspace_profile.dart';
part 'user_workspace_nutrition_widgets.dart';
part 'user_workspace_common_widgets.dart';

class UserWorkspaceScreen extends StatefulWidget {
  const UserWorkspaceScreen({
    required this.account,
    required this.api,
    required this.meals,
    required this.waterMl,
    required this.onAddMeal,
    required this.onUpdateMeal,
    required this.onDeleteMeal,
    required this.onRefresh,
    required this.onLogout,
    required this.onAccountUpdated,
    super.key,
  });

  final LocalAccount account;
  final NutriMateApi api;
  final List<MealRecord> meals;
  final int waterMl;
  final Future<void> Function(MealRecord) onAddMeal;
  final Future<void> Function(String, MealRecord) onUpdateMeal;
  final Future<void> Function(MealRecord) onDeleteMeal;
  final Future<void> Function() onRefresh;
  final VoidCallback onLogout;
  final ValueChanged<LocalAccount> onAccountUpdated;

  @override
  State<UserWorkspaceScreen> createState() => _UserWorkspaceScreenState();
}

class _UserWorkspaceScreenState extends State<UserWorkspaceScreen> {
  int _tab = 0;
  late NutritionGoals _goals;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  final Set<String> _readNotifications = {};
  final Set<String> _dismissedNotifications = {};
  final List<_WaterLogEntry> _waterEntries = [];

  @override
  void initState() {
    super.initState();
    final storedGoals = widget.account.preferences['nutrition_goals'];
    _goals = storedGoals is Map
        ? NutritionGoals.fromJson(Map<String, dynamic>.from(storedGoals))
        : const NutritionGoals();
    _readNotifications.addAll(
      (widget.account.preferences['read_notifications'] as List? ?? const [])
          .whereType<String>(),
    );
    _dismissedNotifications.addAll(
      (widget.account.preferences['dismissed_notifications'] as List? ??
              const [])
          .whereType<String>(),
    );
    _loadWaterEntries();
  }

  Future<void> _loadWaterEntries() async {
    try {
      final entries = await widget.api.waterEntries();
      if (!mounted) return;
      setState(() {
        _waterEntries
          ..clear()
          ..addAll(entries.map(_WaterLogEntry.fromJson));
      });
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMeals = widget.meals
        .where((meal) => DateUtils.isSameDay(meal.createdAt, _selectedDate))
        .toList();
    final pages = [
      _HomeTab(
        account: widget.account,
        goals: _goals,
        meals: selectedMeals,
        allMeals: widget.meals,
        waterMl: widget.waterMl,
        selectedDate: _selectedDate,
        onSelectDate: _selectDate,
        onAddMeal: _showAddMeal,
        onGoToMeals: () => setState(() => _tab = 1),
        onGoToProgress: () => setState(() => _tab = 2),
        onAddWater: _addWaterEntry,
      ),
      _MealsTab(
        meals: selectedMeals,
        selectedDate: _selectedDate,
        onSelectDate: _selectDate,
        onAdd: _showAddMeal,
        onDelete: _confirmDeleteMeal,
        onEdit: _editMeal,
        onDuplicate: _duplicateMeal,
        onShowDetails: _showMealDetails,
      ),
      _ProgressTab(
        api: widget.api,
        meals: selectedMeals,
        allMeals: widget.meals,
        waterMl: widget.waterMl,
        goals: _goals,
        selectedDate: _selectedDate,
        waterEntries: _waterEntries,
        onSelectDate: _selectDate,
        onAddWater: _addWaterEntry,
        onEditWater: _editWaterEntry,
        onDeleteWater: _confirmDeleteWater,
      ),
      _LearnTab(
        api: widget.api,
        account: widget.account,
        onAccountUpdated: widget.onAccountUpdated,
      ),
      _ProfileTab(
        account: widget.account,
        api: widget.api,
        goals: _goals,
        onGoalsChanged: (goals) => setState(() => _goals = goals),
        onLogout: widget.onLogout,
        onAccountUpdated: widget.onAccountUpdated,
      ),
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
                color: const Color(0xFFE4F4EF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.eco, color: AppColors.teal, size: 20),
            ),
            const SizedBox(width: 9),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NutriMate',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  'PERSONAL WELLNESS',
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
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: _showNotifications,
            icon: const Icon(Icons.notifications_none),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 13),
            child: IconButton(
              tooltip: 'Profile and settings',
              onPressed: () => setState(() => _tab = 4),
              padding: EdgeInsets.zero,
              icon: CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFDDF3EC),
                child: Text(
                  widget.account.initials,
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
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
                _UserDesktopSidebar(
                  selectedIndex: _tab,
                  onDestinationSelected: (index) =>
                      setState(() => _tab = index),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
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
              selectedIndex: _tab,
              onDestinationSelected: (index) => setState(() => _tab = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant_outlined),
                  selectedIcon: Icon(Icons.restaurant),
                  label: 'Meals',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: 'Progress',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'Learn',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }

  Future<void> _showAddMeal() async {
    try {
      final foods = await widget.api.foods();
      final categories = await widget.api.categories();
      if (!mounted) return;
      final meals = await showModalBottomSheet<List<MealRecord>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddMealSheet(
          date: _selectedDate,
          foodCatalog: foods.map(_foodDataFromApi).toList(),
          foodCategories: categories
              .map((category) => category['name'] as String)
              .toList(),
          onBarcodeLookup: _lookupFoodByBarcode,
        ),
      );
      if (meals != null && meals.isNotEmpty) {
        setState(
          () => _selectedDate = DateUtils.dateOnly(meals.first.createdAt),
        );
        for (final meal in meals) {
          await _saveMeal(meal);
        }
      }
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _editMeal(MealRecord meal) async {
    try {
      final foods = await widget.api.foods();
      final categories = await widget.api.categories();
      if (!mounted) return;
      final updatedMeals = await showModalBottomSheet<List<MealRecord>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddMealSheet(
          date: meal.createdAt,
          initialMeal: meal,
          foodCatalog: foods.map(_foodDataFromApi).toList(),
          foodCategories: categories
              .map((category) => category['name'] as String)
              .toList(),
          onBarcodeLookup: _lookupFoodByBarcode,
        ),
      );
      if (updatedMeals == null || updatedMeals.isEmpty) return;
      await widget.onUpdateMeal(meal.id, updatedMeals.first);
      setState(
        () => _selectedDate = DateUtils.dateOnly(updatedMeals.first.createdAt),
      );
      for (final updated in updatedMeals.skip(1)) {
        await _saveMeal(updated);
      }
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  _FoodData _foodDataFromApi(Map<String, dynamic> food) => _FoodData(
    food['id'] as int,
    food['name'] as String,
    food['calories'] as int,
    (num.parse('${food['protein']}')).round(),
    (num.parse('${food['carbs']}')).round(),
    (num.parse('${food['fat']}')).round(),
    food['category_name'] as String? ?? 'Other',
    '${food['serving_size']} ${food['serving_unit']}',
    source: food['data_source'] as String? ?? 'Not provided',
  );

  Future<_FoodData?> _lookupFoodByBarcode(String barcode) async {
    final matches = await widget.api.foods(barcode: barcode);
    return matches.isEmpty ? null : _foodDataFromApi(matches.first);
  }

  Future<void> _duplicateMeal(MealRecord meal) async {
    await _saveMeal(
      MealRecord(
        name: meal.name,
        category: meal.category,
        calories: meal.calories,
        protein: meal.protein,
        carbs: meal.carbs,
        fat: meal.fat,
        foodId: meal.foodId,
        servings: meal.servings,
        notes: meal.notes,
        createdAt: _selectedDate,
      ),
    );
    _showMessage('Meal duplicated for the selected date.');
  }

  Future<void> _saveMeal(MealRecord meal) async {
    try {
      await widget.onAddMeal(meal);
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _showMealDetails(MealRecord meal) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal.name,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${meal.category} · ${meal.createdAt.year}-${meal.createdAt.month.toString().padLeft(2, '0')}-${meal.createdAt.day.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Color(0xFF78869A), fontSize: 11),
              ),
              const SizedBox(height: 16),
              Text(
                '${meal.calories} kcal',
                style: const TextStyle(
                  color: Color(0xFF1684E8),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Protein ${meal.protein} g · Carbs ${meal.carbs} g · Fat ${meal.fat} g',
                style: const TextStyle(color: Color(0xFF53647A), fontSize: 12),
              ),
              if (meal.notes.isNotEmpty) ...[
                const SizedBox(height: 11),
                Text('Notes: ${meal.notes}'),
              ],
              const SizedBox(height: 11),
              const Text(
                'Nutrition values are estimates and may not be verified for this food or serving.',
                style: TextStyle(color: Color(0xFF8290A2), fontSize: 10),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _editMeal(meal);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('Edit'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _duplicateMeal(meal);
                    },
                    icon: const Icon(Icons.copy_outlined, size: 17),
                    label: const Text('Duplicate'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _confirmDeleteMeal(meal);
                    },
                    icon: const Icon(Icons.delete_outline, size: 17),
                    label: const Text('Delete'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showMessage(
                      'Food data reports will be available when support services are connected.',
                    ),
                    icon: const Icon(Icons.flag_outlined, size: 17),
                    label: const Text('Report data'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _selectedDate = DateUtils.dateOnly(date));
  }

  Future<void> _addWaterEntry(int amount) async {
    if (amount <= 0) return;
    try {
      final saved = await widget.api.createWaterEntry(amount);
      if (mounted) {
        setState(() => _waterEntries.insert(0, _WaterLogEntry.fromJson(saved)));
      }
      await widget.onRefresh();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _editWaterEntry(_WaterLogEntry entry, int amount) async {
    if (amount <= 0) return;
    final index = _waterEntries.indexWhere((item) => item.id == entry.id);
    if (index < 0) return;
    try {
      final saved = await widget.api.updateWaterEntry(
        int.parse(entry.id),
        amountMl: amount,
      );
      if (mounted) {
        setState(() => _waterEntries[index] = _WaterLogEntry.fromJson(saved));
      }
      await widget.onRefresh();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _deleteWaterEntry(_WaterLogEntry entry) async {
    final index = _waterEntries.indexWhere((item) => item.id == entry.id);
    if (index < 0) return;
    try {
      await widget.api.deleteWaterEntry(int.parse(entry.id));
      if (mounted) setState(() => _waterEntries.removeAt(index));
      await widget.onRefresh();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _confirmDeleteWater(_WaterLogEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete water entry?'),
        content: Text('Remove ${entry.amount} ml from this session’s history?'),
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
    if (confirmed == true) await _deleteWaterEntry(entry);
  }

  Future<void> _refreshDashboard() async {
    try {
      await widget.onRefresh();
      await _loadWaterEntries();
      _showMessage('Dashboard refreshed from the NutriMate API.');
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _showNotifications() async {
    late final List<Map<String, dynamic>> announcements;
    late final List<Map<String, dynamic>> recommendations;
    try {
      announcements = await widget.api.announcements();
      recommendations = await widget.api.recommendations();
    } on ApiException catch (error) {
      _showMessage(error.message);
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, updateSheet) => SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        updateSheet(() {
                          _readNotifications.addAll(
                            announcements.map((item) => '${item['id']}'),
                          );
                          _readNotifications.addAll(
                            recommendations.map((item) => 'rule-${item['id']}'),
                          );
                        });
                        _saveNotificationState();
                      },
                      child: const Text('Mark all as read'),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                if (announcements.isEmpty && recommendations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No announcements or recommendations yet.',
                        style: TextStyle(color: Color(0xFF78869A)),
                      ),
                    ),
                  )
                else ...[
                  ...announcements.map((announcement) {
                    final id = '${announcement['id']}';
                    if (_dismissedNotifications.contains(id)) {
                      return const SizedBox.shrink();
                    }
                    return _NotificationPreviewTile(
                      icon: Icons.campaign_outlined,
                      title: announcement['title'] as String,
                      detail: announcement['body'] as String,
                      isRead: _readNotifications.contains(id),
                      onMarkRead: () {
                        updateSheet(() => _readNotifications.add(id));
                        _saveNotificationState();
                      },
                      onDismiss: () {
                        updateSheet(() => _dismissedNotifications.add(id));
                        _saveNotificationState();
                      },
                    );
                  }),
                  ...recommendations.map((rule) {
                    final id = 'rule-${rule['id']}';
                    if (_dismissedNotifications.contains(id)) {
                      return const SizedBox.shrink();
                    }
                    return _NotificationPreviewTile(
                      icon: Icons.lightbulb_outline,
                      title: rule['title'] as String,
                      detail: rule['message'] as String,
                      isRead: _readNotifications.contains(id),
                      onMarkRead: () {
                        updateSheet(() => _readNotifications.add(id));
                        _saveNotificationState();
                      },
                      onDismiss: () {
                        updateSheet(() => _dismissedNotifications.add(id));
                        _saveNotificationState();
                      },
                    );
                  }),
                ],
                const SizedBox(height: 9),
                const Text(
                  'Announcements and recommendations are loaded from the NutriMate API.',
                  style: TextStyle(color: Color(0xFF8290A2), fontSize: 10),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() => _tab = 4);
                    },
                    icon: const Icon(Icons.tune, size: 17),
                    label: const Text('Notification settings'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveNotificationState() async {
    try {
      final updated = await widget.api.updateProfile(
        name: widget.account.name,
        preferences: {
          ...widget.account.preferences,
          'read_notifications': _readNotifications.toList(),
          'dismissed_notifications': _dismissedNotifications.toList(),
        },
      );
      if (mounted) widget.onAccountUpdated(updated);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _confirmDeleteMeal(MealRecord meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove meal?'),
        content: Text('Remove ${meal.name} from today’s food log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await widget.onDeleteMeal(meal);
      } on ApiException catch (error) {
        _showMessage(error.message);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
