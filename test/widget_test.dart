import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nutrimate/main.dart';
import 'package:nutrimate/services/nutrimate_api.dart';

late NutriMateApi _api;
late List<Map<String, dynamic>> _accounts;
late Map<int, String> _passwords;
late List<Map<String, dynamic>> _meals;
late List<Map<String, dynamic>> _categories;
late List<Map<String, dynamic>> _foods;
late Map<int, int> _water;
Map<String, dynamic>? _currentAccount;
int _nextId = 10;

Future<void> _openApp(WidgetTester tester) async {
  await tester.pumpWidget(NutriMateApp(api: _api));
  await tester.pumpAndSettle();
}

http.Response _response(int status, Object? body) => http.Response(
  body == null ? '' : jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Future<http.Response> _handleApi(http.Request request) async {
  final path = request.url.path.replaceFirst('/api/v1/', '');
  final body = request.body.isEmpty
      ? <String, dynamic>{}
      : jsonDecode(request.body) as Map<String, dynamic>;
  if (path == 'auth/register/' && request.method == 'POST') {
    final account = {
      'id': _nextId++,
      'name': body['name'],
      'email': (body['email'] as String).toLowerCase(),
      'role': 'user',
      'is_active': true,
      'date_joined': DateTime.now().toUtc().toIso8601String(),
    };
    _accounts.add(account);
    _passwords[account['id'] as int] = body['password'] as String;
    return _response(201, account);
  }
  if (path == 'auth/token/' && request.method == 'POST') {
    final matches = _accounts.where(
      (account) =>
          account['email'] == (body['email'] as String).toLowerCase() &&
          _passwords[account['id']] == body['password'] &&
          account['is_active'] == true,
    );
    if (matches.isEmpty) {
      return _response(401, {'detail': 'Invalid credentials.'});
    }
    _currentAccount = matches.first;
    return _response(200, {'access': 'test-access', 'refresh': 'test-refresh'});
  }
  if (path == 'auth/token/refresh/' && request.method == 'POST') {
    return _response(200, {'access': 'test-access'});
  }
  if (path == 'auth/me/' && request.method == 'GET') {
    return _response(200, _currentAccount);
  }
  if (path == 'meals/' && request.method == 'GET') {
    final rows = _meals
        .where((meal) => meal['user_id'] == _currentAccount?['id'])
        .map((meal) => Map<String, dynamic>.from(meal)..remove('user_id'))
        .toList();
    return _response(200, rows);
  }
  if (path == 'meals/' && request.method == 'POST') {
    final meal = {
      ...body,
      'id': _nextId++,
      'user_id': _currentAccount?['id'],
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _meals.insert(0, meal);
    return _response(201, Map<String, dynamic>.from(meal)..remove('user_id'));
  }
  if (path.startsWith('meals/') && request.method == 'PATCH') {
    final id = int.parse(path.split('/')[1]);
    final index = _meals.indexWhere(
      (meal) => meal['id'] == id && meal['user_id'] == _currentAccount?['id'],
    );
    if (index < 0) return _response(404, {'detail': 'Not found.'});
    _meals[index] = {..._meals[index], ...body};
    return _response(
      200,
      Map<String, dynamic>.from(_meals[index])..remove('user_id'),
    );
  }
  if (path.startsWith('meals/') && request.method == 'DELETE') {
    final id = int.parse(path.split('/')[1]);
    _meals.removeWhere(
      (meal) => meal['id'] == id && meal['user_id'] == _currentAccount?['id'],
    );
    return _response(204, null);
  }
  if (path == 'water/today/' && request.method == 'GET') {
    return _response(200, {
      'date': '2026-10-14',
      'amount_ml': _water[_currentAccount?['id']] ?? 0,
    });
  }
  if (path == 'water/today/' && request.method == 'PUT') {
    _water[_currentAccount!['id'] as int] = body['amount_ml'] as int;
    return _response(200, {
      'date': '2026-10-14',
      'amount_ml': body['amount_ml'],
    });
  }
  if (path == 'admin/dashboard/' && request.method == 'GET') {
    if (_currentAccount?['role'] != 'admin') {
      return _response(403, {'detail': 'Admin access is required.'});
    }
    return _response(200, {
      'registered_accounts': _accounts.length,
      'active_accounts': _accounts
          .where((user) => user['is_active'] == true)
          .length,
      'meal_records': _meals.length,
      'food_categories': _categories.length,
      'food_records': _foods.length,
      'published_food_records': _foods
          .where((food) => food['status'] == 'published')
          .length,
      'incomplete_food_records': 0,
      'new_registrations_today': 0,
    });
  }
  if (path == 'admin/users/' && request.method == 'GET') {
    if (_currentAccount?['role'] != 'admin') {
      return _response(403, {'detail': 'Admin access is required.'});
    }
    final search = request.url.queryParameters['search']?.toLowerCase() ?? '';
    return _response(
      200,
      _accounts
          .where(
            (user) =>
                (user['name'] as String).toLowerCase().contains(search) ||
                (user['email'] as String).toLowerCase().contains(search),
          )
          .toList(),
    );
  }
  if (path == 'admin/users/create/' && request.method == 'POST') {
    if (_currentAccount?['role'] != 'admin') {
      return _response(403, {'detail': 'Admin access is required.'});
    }
    final user = {
      'id': _nextId++,
      'name': body['name'],
      'email': body['email'],
      'role': 'user',
      'is_active': true,
      'date_joined': DateTime.now().toUtc().toIso8601String(),
    };
    _accounts.add(user);
    _passwords[user['id'] as int] = body['password'] as String;
    return _response(201, user);
  }
  if (path.startsWith('admin/users/') && request.method == 'PATCH') {
    final id = int.parse(path.split('/')[2]);
    final user = _accounts.firstWhere((item) => item['id'] == id);
    user['is_active'] = body['is_active'];
    return _response(200, user);
  }
  if (path == 'categories/' && request.method == 'GET') {
    return _response(200, _categories);
  }
  if (path == 'categories/' && request.method == 'POST') {
    final category = {
      'id': _nextId++,
      'name': body['name'],
      'is_active': true,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _categories.add(category);
    return _response(201, category);
  }
  if (path.startsWith('categories/') && request.method == 'PATCH') {
    final id = int.parse(path.split('/')[1]);
    final category = _categories.firstWhere((item) => item['id'] == id);
    category['is_active'] = body['is_active'];
    return _response(200, category);
  }
  if (path == 'foods/' && request.method == 'GET') {
    final search = request.url.queryParameters['search']?.toLowerCase() ?? '';
    return _response(
      200,
      _foods
          .where(
            (food) => (food['name'] as String).toLowerCase().contains(search),
          )
          .toList(),
    );
  }
  if (path == 'foods/' && request.method == 'POST') {
    final food = {...body, 'id': _nextId++, 'category_name': 'Fruits'};
    _foods.add(food);
    return _response(201, food);
  }
  if (path.startsWith('foods/') && request.method == 'PATCH') {
    final id = int.parse(path.split('/')[1]);
    final index = _foods.indexWhere((food) => food['id'] == id);
    _foods[index] = {..._foods[index], ...body};
    return _response(200, _foods[index]);
  }
  if (path.startsWith('foods/') && request.method == 'DELETE') {
    final id = int.parse(path.split('/')[1]);
    _foods.removeWhere((food) => food['id'] == id);
    return _response(204, null);
  }
  return _response(404, {'detail': 'No fake route for $path'});
}

Future<void> _createUser(WidgetTester tester) async {
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Create user account'));
  await tester.tap(find.text('Create user account'));
  await tester.pumpAndSettle();
  expect(find.text('Admin'), findsNothing);
  expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  await tester.enterText(find.byType(TextFormField).at(0), 'Mia Santos');
  await tester.enterText(find.byType(TextFormField).at(1), 'mia@example.com');
  await tester.enterText(find.byType(TextFormField).at(2), 'mia12345');
  await tester.ensureVisible(find.text('Create and continue'));
  await tester.tap(find.text('Create and continue'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _accounts = [
      {
        'id': 1,
        'name': 'Admin Person',
        'email': 'nutrimate@admin.com',
        'role': 'admin',
        'is_active': true,
        'date_joined': DateTime.utc(2026, 1, 1).toIso8601String(),
      },
    ];
    _passwords = {1: 'AdminPass123!'};
    _meals = [];
    _categories = [
      {
        'id': 2,
        'name': 'Fruits',
        'is_active': true,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    ];
    _foods = [];
    _water = {};
    _currentAccount = null;
    _nextId = 10;
    _api = NutriMateApi(
      client: MockClient(_handleApi),
      baseUrl: 'http://test/api/v1/',
    );
  });

  testWidgets('new user account is created and authenticated by the API', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _openApp(tester);
    expect(find.text('Nourish your\nbest self.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Continue as User'), findsNothing);
    await _createUser(tester);
    expect(find.text('Good day, Mia!'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    tester.view.physicalSize = const Size(1440, 1000);
    await tester.pumpAndSettle();
    expect(find.text('YOUR WORKSPACE'), findsOneWidget);
    expect(find.text('Meals logged'), findsOneWidget);
    expect(find.text('Water intake'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('My profile'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit nutrition targets'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '2000');
    await tester.enterText(find.byType(TextField).at(1), '250');
    await tester.enterText(find.byType(TextField).at(2), '100');
    await tester.enterText(find.byType(TextField).at(3), '65');
    await tester.tap(find.text('Save targets'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('of 2000 kcal'), findsOneWidget);
    expect(find.text('2000 kcal remaining'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Already have an account? Sign in'),
      300,
    );
    await tester.ensureVisible(find.text('Already have an account? Sign in'));
    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'mia@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'mia12345');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Good day, Mia!'), findsOneWidget);
  });

  testWidgets('meal and water entries persist in the API across app restart', (
    WidgetTester tester,
  ) async {
    await _openApp(tester);
    await _createUser(tester);
    await tester.tap(find.text('Meals'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add meal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Oatmeal');
    await tester.enterText(find.byType(TextFormField).at(1), '150');
    await tester.enterText(find.byType(TextFormField).at(2), '5');
    await tester.enterText(find.byType(TextFormField).at(3), '27');
    await tester.enterText(find.byType(TextFormField).at(4), '3');
    await tester.ensureVisible(find.text('Add another item'));
    await tester.tap(find.text('Add another item'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Banana');
    await tester.enterText(find.byType(TextFormField).at(1), '105');
    await tester.enterText(find.byType(TextFormField).at(2), '1');
    await tester.enterText(find.byType(TextFormField).at(3), '27');
    await tester.enterText(find.byType(TextFormField).at(4), '0');
    await tester.ensureVisible(find.text('Save to today’s diary'));
    await tester.tap(find.text('Save to today’s diary'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ 250 ml'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await _openApp(tester);

    expect(find.text('Good day, Mia!'), findsOneWidget);
    await tester.tap(find.text('Meals'));
    await tester.pumpAndSettle();
    expect(find.text('Oatmeal'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('250 ml'), findsOneWidget);
  });

  testWidgets('server-provisioned Admin sees protected dashboard tools', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _openApp(tester);
    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'nutrimate@admin.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'AdminPass123!');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Workspace administration overview'), findsOneWidget);
    expect(find.text('API CONNECTED'), findsOneWidget);
    expect(find.text('Registered accounts'), findsOneWidget);
    expect(find.text('Meal records'), findsOneWidget);
    expect(find.text('Backend API'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Audit activity'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('More admin tools'), findsOneWidget);
    await tester.tap(find.text('Nutrition content').last);
    await tester.pumpAndSettle();
    expect(find.text('Not connected yet'), findsOneWidget);
    expect(
      find.textContaining('publishing API are not configured.'),
      findsOneWidget,
    );

    tester.view.physicalSize = const Size(1440, 1000);
    await tester.pumpAndSettle();
    expect(find.text('ADMIN CONSOLE'), findsOneWidget);
    expect(find.text('Recommendation rules'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
