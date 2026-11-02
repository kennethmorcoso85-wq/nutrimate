import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: AppColors.navy,
      fontSize: 16,
      fontWeight: FontWeight.w800,
    ),
  );
}
