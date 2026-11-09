import 'package:flutter/material.dart';

import 'models/local_account.dart';
import 'models/meal_record.dart';
import 'screens/admin_workspace_screen.dart';
import 'screens/auth_flow_screen.dart';
import 'screens/user_workspace_screen.dart';
import 'services/nutrimate_api.dart';
import 'utils/app_colors.dart';

class NutriMateApp extends StatefulWidget {
  const NutriMateApp({super.key, this.api});

  final NutriMateApi? api;

  @override
  State<NutriMateApp> createState() => _NutriMateAppState();
}

class _NutriMateAppState extends State<NutriMateApp> {
  late final NutriMateApi _api;
  LocalAccount? _activeAccount;
  List<MealRecord> _meals = [];
  int _waterMl = 0;
  bool _ready = false;
  String? _startupError;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? NutriMateApi();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _api.initialize();
      final account = await _api.restoreSession();
      if (account != null) {
        _activeAccount = account;
        await _loadUserData(account);
      }
      if (mounted) setState(() => _ready = true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _startupError = error.message;
          _ready = true;
        });
      }
    }
  }

  Future<void> _loadUserData(LocalAccount account) async {
    if (account.isAdmin) {
      _meals = [];
      _waterMl = 0;
      return;
    }
    _meals = await _api.meals();
    _waterMl = await _api.todayWater();
  }

  Future<void> _onAccountOpened(LocalAccount account) async {
    try {
      await _loadUserData(account);
    } on ApiException {
      rethrow;
    }
    if (!mounted) return;
    setState(() {
      _activeAccount = account;
    });
  }

  Future<void> _onLogout() async {
    await _api.logout();
    setState(() => _activeAccount = null);
  }

  void _onAccountUpdated(LocalAccount account) {
    if (mounted) setState(() => _activeAccount = account);
  }

  Future<void> _addMeal(MealRecord meal) async {
    final saved = await _api.createMeal(meal);
    if (mounted) setState(() => _meals.insert(0, saved));
  }

  Future<void> _removeMeal(MealRecord meal) async {
    await _api.deleteMeal(meal);
    if (mounted) {
      setState(() => _meals.removeWhere((item) => item.id == meal.id));
    }
  }

  Future<void> _updateMeal(String id, MealRecord meal) async {
    final updated = await _api.updateMeal(id, meal);
    if (mounted) {
      setState(() {
        final index = _meals.indexWhere((item) => item.id == id);
        if (index >= 0) _meals[index] = updated;
      });
    }
  }

  Future<void> _refreshUserData() async {
    final account = _activeAccount;
    if (account == null || account.isAdmin) return;
    final meals = await _api.meals();
    final waterMl = await _api.todayWater();
    if (mounted) {
      setState(() {
        _meals = meals;
        _waterMl = waterMl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          primary: AppColors.teal,
          secondary: AppColors.blue,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.navy,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4F7F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
      home: !_ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _startupError != null
          ? Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 42),
                      const SizedBox(height: 12),
                      Text(_startupError!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => setState(() {
                          _ready = false;
                          _startupError = null;
                          _initialize();
                        }),
                        child: const Text('Retry connection'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : _activeAccount == null
          ? AuthFlowScreen(api: _api, onAccountOpened: _onAccountOpened)
          : _activeAccount!.isAdmin
          ? AdminWorkspaceScreen(
              account: _activeAccount!,
              api: _api,
              onLogout: _onLogout,
            )
          : UserWorkspaceScreen(
              account: _activeAccount!,
              api: _api,
              meals: _meals,
              waterMl: _waterMl,
              onAddMeal: _addMeal,
              onUpdateMeal: _updateMeal,
              onDeleteMeal: _removeMeal,
              onRefresh: _refreshUserData,
              onLogout: _onLogout,
              onAccountUpdated: _onAccountUpdated,
            ),
    );
  }
}
