import 'package:flutter/material.dart';

import '../../models/nutrition_goals.dart';

class GoalsEditor extends StatefulWidget {
  const GoalsEditor({required this.goals, super.key});

  final NutritionGoals goals;

  @override
  State<GoalsEditor> createState() => _GoalsEditorState();
}

class _GoalsEditorState extends State<GoalsEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _calories;
  late final TextEditingController _carbs;
  late final TextEditingController _protein;
  late final TextEditingController _fat;

  @override
  void initState() {
    super.initState();
    _calories = TextEditingController(text: widget.goals.calories.toString());
    _carbs = TextEditingController(text: widget.goals.carbs.toString());
    _protein = TextEditingController(text: widget.goals.protein.toString());
    _fat = TextEditingController(text: widget.goals.fat.toString());
  }

  @override
  void dispose() {
    _calories.dispose();
    _carbs.dispose();
    _protein.dispose();
    _fat.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      NutritionGoals(
        calories: int.parse(_calories.text),
        carbs: int.parse(_carbs.text),
        protein: int.parse(_protein.text),
        fat: int.parse(_fat.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Set nutrition goals'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _goalField(_calories, 'Calories (1000–5000)', 1000, 5000),
            _goalField(_carbs, 'Carbs (g)', 20, 1000),
            _goalField(_protein, 'Protein (g)', 10, 500),
            _goalField(_fat, 'Fat (g)', 10, 500),
            const SizedBox(height: 4),
            const Text(
              'Targets are estimates. Ask a qualified professional for personalized guidance.',
              style: TextStyle(color: Color(0xFF78869A), fontSize: 12),
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
      FilledButton(onPressed: _save, child: const Text('Save goals')),
    ],
  );

  Widget _goalField(
    TextEditingController controller,
    String label,
    int min,
    int max,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final number = int.tryParse(value ?? '');
          return number == null || number < min || number > max
              ? 'Enter $min–$max'
              : null;
        },
      ),
    );
  }
}
