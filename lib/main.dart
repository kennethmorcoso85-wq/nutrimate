import 'package:flutter/material.dart';

import 'app.dart';

export 'app.dart' show NutriMateApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NutriMateApp());
}
