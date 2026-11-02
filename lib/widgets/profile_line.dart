import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class ProfileLine extends StatelessWidget {
  const ProfileLine({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 19, color: AppColors.blue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF75839A))),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
