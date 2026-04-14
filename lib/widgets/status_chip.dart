import 'package:flutter/material.dart';

import '../app/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.accent,
    this.textColor,
  });

  final String label;
  final Color accent;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? wsInk.withValues(alpha: 0.86),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
