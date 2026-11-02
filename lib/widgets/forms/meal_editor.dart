import 'package:flutter/material.dart';

import '../../models/meal_entry.dart';
import '../../utils/app_colors.dart';

class MealEditor extends StatefulWidget {
  const MealEditor({this.meal, super.key});

  final MealEntry? meal;

  @override
  State<MealEditor> createState() => _MealEditorState();
}

class _MealEditorState extends State<MealEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _calories;
  late final TextEditingController _carbs;
  late final TextEditingController _protein;
  late final TextEditingController _fat;
  late String _category;

  @override
  void initState() {
    super.initState();
    final meal = widget.meal;
    _name = TextEditingController(text: meal?.name ?? '');
    _calories = TextEditingController(text: meal?.calories.toString() ?? '');
    _carbs = TextEditingController(text: meal?.carbs.toString() ?? '');
    _protein = TextEditingController(text: meal?.protein.toString() ?? '');
    _fat = TextEditingController(text: meal?.fat.toString() ?? '');
    _category = meal?.category ?? 'Breakfast';
  }

  @override
  void dispose() {
    _name.dispose();
    _calories.dispose();
    _carbs.dispose();
    _protein.dispose();
    _fat.dispose();
    super.dispose();
  }

  int? _positiveInt(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 0 || number > 10000) return null;
    return number;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final meal = MealEntry(
      id: widget.meal?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      category: _category,
      calories: int.parse(_calories.text),
      carbs: int.parse(_carbs.text),
      protein: int.parse(_protein.text),
      fat: int.parse(_fat.text),
      createdAt: widget.meal?.createdAt ?? DateTime.now(),
    );
    Navigator.pop(context, meal);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5DDE8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.meal == null ? 'Log food intake' : 'Edit meal',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Food or meal name',
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a food name'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Meal type'),
                  items: const ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _category = value!),
                ),
                const SizedBox(height: 12),
                _numberField(
                  _calories,
                  'Calories (kcal)',
                  Icons.local_fire_department,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _numberField(_carbs, 'Carbs (g)', null)),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _numberField(_protein, 'Protein (g)', null),
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: _numberField(_fat, 'Fat (g)', null)),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(
                      widget.meal == null ? 'Save meal' : 'Update meal',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    IconData? icon,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
      validator: (value) =>
          _positiveInt(value) == null ? 'Enter 0–10000' : null,
    );
  }
}
