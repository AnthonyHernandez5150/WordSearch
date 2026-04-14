import 'dart:math';
import 'package:flutter/material.dart';

class CelebrationBurst extends StatelessWidget {
  const CelebrationBurst({
    super.key,
    required this.color,
    this.size = 120,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    const List<double> angles = <double>[
      -1.8,
      -1.25,
      -0.75,
      -0.25,
      0.35,
      0.9,
      1.45,
    ];

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutBack,
        builder: (BuildContext context, double value, Widget? child) {
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: angles.map((double angle) {
                final double distance = 10 + (size * 0.34 - 10) * value;
                final double dotSize =
                    size * 0.06 + (size * 0.14 - size * 0.06) * value;
                final double x = cos(angle) * distance;
                final double y = sin(angle) * distance;
                return Positioned(
                  left: size / 2 + x,
                  top: size / 2 + y,
                  child: Opacity(
                    opacity: (1.08 - value).clamp(0, 1),
                    child: Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.72),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
