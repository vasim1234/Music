import 'package:just_audio/just_audio.dart';

class RealEqualizerService {
  static AudioPlayer? _player;
  static bool _isInitialized = false;
  static List<double> _bandLevels = List.filled(10, 0.0);
  static bool _isEnabled = true;

  static Future<void> initialize(AudioPlayer player) async {
    _player = player;
    _isInitialized = true;
  }

  static Future<void> setBandLevel(int index, double level) async {
    if (!_isInitialized || _player == null) return;
    if (index < 0 || index >= _bandLevels.length) return;

    _bandLevels[index] = level.clamp(-12.0, 12.0);
    
    // Apply all bands as volume/pitch adjustment
    // This is a simulation since just_audio doesn't have native equalizer
    _applySimulatedEffects();
  }

  static void _applySimulatedEffects() {
    if (_player == null) return;
    
    // Calculate average boost
    double avgBoost = _bandLevels.reduce((a, b) => a + b) / _bandLevels.length;
    
    // Convert dB to volume multiplier
    double volumeMultiplier = 1.0 + (avgBoost / 30.0);
    _player!.setVolume(volumeMultiplier.clamp(0.0, 2.0));
  }

  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (_player != null) {
      if (enabled) {
        _applySimulatedEffects();
      } else {
        _player!.setVolume(1.0);
      }
    }
  }

  static Future<void> reset() async {
    _bandLevels = List.filled(10, 0.0);
    _isEnabled = true;
    if (_player != null) {
      _player!.setVolume(1.0);
    }
  }

  static void dispose() {
    _player = null;
    _isInitialized = false;
  }

  static bool get isInitialized => _isInitialized;
  static bool get isEnabled => _isEnabled;
  static List<double> get bandLevels => List.unmodifiable(_bandLevels);
}
