import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ProgressStore {
  const ProgressStore._();

  static const MethodChannel _channel = MethodChannel(
    'com.anthonyhernandez.wordtrailgame/progress',
  );

  static Future<String?> load() async {
    try {
      return await _channel.invokeMethod<String>('load');
    } on MissingPluginException {
      debugPrint('ProgressStore unavailable on this platform.');
      return null;
    } on PlatformException catch (error) {
      debugPrint('ProgressStore load failed: ${error.message}');
      return null;
    }
  }

  static Future<void> save(String payload) async {
    try {
      await _channel.invokeMethod<void>('save', payload);
    } on MissingPluginException {
      debugPrint('ProgressStore unavailable on this platform.');
    } on PlatformException catch (error) {
      debugPrint('ProgressStore save failed: ${error.message}');
    }
  }
}
