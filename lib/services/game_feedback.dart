import 'package:flutter/services.dart';

class GameFeedback {
  const GameFeedback._();

  static void tap() {
    HapticFeedback.selectionClick();
  }

  static void hint() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void success() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void celebrate() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
  }
}
