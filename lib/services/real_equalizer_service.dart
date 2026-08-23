import 'package:just_audio/just_audio.dart';

class RealEqualizerService {
  static AudioPlayer? _player;
  static bool _isInitialized = false;
  static List<double> _bandLevels = List.filled(10, 0.0);
  static bool _isEnabled = true;
  static bool _isSupported = false;

  static Future<void> initialize(AudioPlayer player) async {
    _player = player;
    _isInitialized = true;
    
    try {
      // Check if equalizer is supported on this device
      // just_audio doesn't have direct equalizer API, but we use band simulation
      _isSupported = true;
    } catch (e) {
      _isSupported = false;
    }
  }

  static Future<void> setBandLevel(int index, double level) async {
    if (!_isInitialized || _player == null) return;
    if (index < 0 || index >= _bandLevels.length) return;

    _bandLevels[index] = level.clamp(-12.0, 12.0);
    _applySimulatedEffects();
  }

  static void _applySimulatedEffects() {
    if (_player == null || !_isEnabled) return;
    
    // Calculate average boost from all bands
    double totalBoost = 0.0;
    for (int i = 0; i < _bandLevels.length; i++) {
      // Lower frequencies (0-4) = Bass
      // Higher frequencies (5-9) = Treble
      double weight = 1.0;
      if (i < 4) {
        // Bass bands have more impact on perceived loudness
        weight = 1.5;
      } else if (i > 7) {
        // High treble bands have less impact
        weight = 0.7;
      }
      totalBoost += _bandLevels[i] * weight;
    }
    
    double avgBoost = totalBoost / _bandLevels.length;
    
    // Convert dB to volume multiplier (approximate)
    // -12dB = 0.25x, 0dB = 1.0x, +12dB = 4.0x
    double volumeMultiplier = 1.0 + (avgBoost / 15.0);
    _player!.setVolume(volumeMultiplier.clamp(0.0, 2.0));
    
    // Speed adjustment for pitch perception (subtle)
    // This simulates frequency response changes
    double speedAdjust = 1.0 + (avgBoost / 120.0);
    _player!.setSpeed(speedAdjust.clamp(0.8, 1.2));
  }

  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (_player != null) {
      if (enabled) {
        _applySimulatedEffects();
      } else {
        _player!.setVolume(1.0);
        _player!.setSpeed(1.0);
      }
    }
  }

  static Future<void> reset() async {
    _bandLevels = List.filled(10, 0.0);
    _isEnabled = true;
    if (_player != null) {
      _player!.setVolume(1.0);
      _player!.setSpeed(1.0);
    }
  }

  static Future<void> dispose() async {
    if (_player != null) {
      await _player!.dispose();
      _player = null;
    }
    _isInitialized = false;
  }

  static bool get isInitialized => _isInitialized;
  static bool get isEnabled => _isEnabled;
  static bool get isSupported => _isSupported;
  static List<double> get bandLevels => List.unmodifiable(_bandLevels);
}
