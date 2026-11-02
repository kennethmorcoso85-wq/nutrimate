import 'package:flutter/material.dart';

import '../../models/student_profile.dart';

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({required this.profile, super.key});

  final StudentProfile profile;

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _grade;
  late final TextEditingController _height;
  late final TextEditingController _weight;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _grade = TextEditingController(text: widget.profile.grade);
    _height = TextEditingController(text: widget.profile.height.toString());
    _weight = TextEditingController(text: widget.profile.weight.toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _grade.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      StudentProfile(
        name: _name.text.trim(),
        grade: _grade.text.trim(),
        role: widget.profile.role,
        height: double.parse(_height.text),
        weight: double.parse(_weight.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit profile'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Enter at least 2 characters'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _grade,
              decoration: const InputDecoration(labelText: 'About me'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _height,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Height (cm)'),
              validator: (value) {
                final number = double.tryParse(value ?? '');
                return number == null || number < 50 || number > 250
                    ? 'Enter 50–250 cm'
                    : null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              validator: (value) {
                final number = double.tryParse(value ?? '');
                return number == null || number < 10 || number > 300
                    ? 'Enter 10–300 kg'
                    : null;
              },
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
      FilledButton(onPressed: _save, child: const Text('Save profile')),
    ],
  );
}
