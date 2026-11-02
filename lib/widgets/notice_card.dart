import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class NoticeCard extends StatelessWidget {
  const NoticeCard({
    required this.message,
    this.isHigh = false,
    this.positive = false,
    super.key,
  });

  final String message;
  final bool isHigh;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive
        ? AppColors.teal
        : isHigh
        ? const Color(0xFFCA5151)
        : const Color(0xFFBD7A13);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              positive
                  ? Icons.check_circle_outline
                  : isHigh
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  positive ? 'Looking good' : 'Nutrition check-in',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF586982),
                    height: 1.35,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
