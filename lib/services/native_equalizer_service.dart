import 'package:flutter/services.dart';

class NativeEqualizerService {
  static const MethodChannel _channel = MethodChannel('equalizer_channel');
  static bool _isInitialized = false;
  static List<double> _bandLevels = List.filled(10, 0.0);
  static bool _isEnabled = true;
  static int _bandCount = 0;

  static Future<void> initialize(int audioSessionId) async {
    try {
      final result = await _channel.invokeMethod('init', {'sessionId': audioSessionId});
      _bandCount = result as int? ?? 5;
      _isInitialized = true;
      print("✅ Equalizer initialized with $_bandCount bands");
    } catch (e) {
      print("❌ Equalizer init failed: $e");
      _isInitialized = false;
    }
  }

  static Future<void> setBandLevel(int index, double level) async {
    if (!_isInitialized || index >= _bandCount) return;
    _bandLevels[index] = level;
    
    try {
      await _channel.invokeMethod('setBandLevel', {
        'band': index,
        'level': (level * 100).round(),
      });
    } catch (e) {
      print("❌ Set band level failed: $e");
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    try {
      await _channel.invokeMethod('setEnabled', {'enabled': enabled});
    } catch (e) {
      print("❌ Set enabled failed: $e");
    }
  }

  static Future<void> reset() async {
    _bandLevels = List.filled(_bandCount, 0.0);
    for (int i = 0; i < _bandCount; i++) {
      await setBandLevel(i, 0.0);
    }
  }

  static Future<void> release() async {
    try {
      await _channel.invokeMethod('release');
    } catch (e) {}
    _isInitialized = false;
  }

  static bool get isInitialized => _isInitialized;
  static bool get isEnabled => _isEnabled;
  static List<double> get bandLevels => List.unmodifiable(_bandLevels);
  static int get bandCount => _bandCount;
}
