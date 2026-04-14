import 'package:flutter/material.dart';

import '../app/app_colors.dart';

enum Difficulty { calm, explorer, expert }

extension DifficultyMeta on Difficulty {
  String get label => switch (this) {
    Difficulty.calm => 'Calm',
    Difficulty.explorer => 'Explorer',
    Difficulty.expert => 'Expert',
  };

  String get description => switch (this) {
    Difficulty.calm =>
      'Readable boards, shorter word lists, and easy puzzle nights.',
    Difficulty.explorer =>
      'Balanced daily play with mixed directions and pace.',
    Difficulty.expert =>
      'Reverse routes, decoys, and shorter words hidden in dense boards.',
  };

  String get paceLabel => switch (this) {
    Difficulty.calm => 'No timer',
    Difficulty.explorer => '6 min focus',
    Difficulty.expert => '4 min sprint',
  };

  IconData get icon => switch (this) {
    Difficulty.calm => Icons.spa_rounded,
    Difficulty.explorer => Icons.explore_rounded,
    Difficulty.expert => Icons.bolt_rounded,
  };

  Color get accent => switch (this) {
    Difficulty.calm => wtMint,
    Difficulty.explorer => wtCyan,
    Difficulty.expert => wtPurple,
  };
}
