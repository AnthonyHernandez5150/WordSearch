import 'dart:async';

import 'package:flutter/services.dart';

class GameFeedback {
  const GameFeedback._();

  static const MethodChannel _channel = MethodChannel('wordtrail/feedback');
  static final Map<String, DateTime> _lastSoundAt = <String, DateTime>{};
  static bool _soundEnabled = true;

  static bool get soundEnabled => _soundEnabled;

  static void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  static void tap() {
    HapticFeedback.selectionClick();
  }

  static void soft() {
    HapticFeedback.selectionClick();
    _play('soft');
  }

  static void hint() {
    HapticFeedback.lightImpact();
    _play('hint');
  }

  static void pause() {
    HapticFeedback.lightImpact();
    _play('pause');
  }

  static void resume() {
    HapticFeedback.lightImpact();
    _play('resume');
  }

  static void success() {
    HapticFeedback.mediumImpact();
    _play('success');
  }

  static void celebrate() {
    HapticFeedback.heavyImpact();
    _play('celebrate');
  }

  static void _play(String event) {
    if (!_soundEnabled || !_canPlay(event)) {
      return;
    }
    unawaited(_playOnPlatform(event));
  }

  static bool _canPlay(String event) {
    final DateTime now = DateTime.now();
    final DateTime? lastPlayed = _lastSoundAt[event];
    final Duration minimumGap = switch (event) {
      'soft' => const Duration(milliseconds: 220),
      'hint' => const Duration(milliseconds: 450),
      'pause' || 'resume' => const Duration(milliseconds: 180),
      'success' => const Duration(milliseconds: 280),
      'celebrate' => const Duration(milliseconds: 900),
      _ => const Duration(milliseconds: 250),
    };
    if (lastPlayed != null && now.difference(lastPlayed) < minimumGap) {
      return false;
    }
    _lastSoundAt[event] = now;
    return true;
  }

  static Future<void> _playOnPlatform(String event) async {
    try {
      await _channel.invokeMethod<void>('play', <String, String>{
        'event': event,
      });
    } on MissingPluginException {
      await SystemSound.play(SystemSoundType.click);
    } on PlatformException {
      // Sound should never block gameplay if a device rejects a tone request.
    }
  }
}
