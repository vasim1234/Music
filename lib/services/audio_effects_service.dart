import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ReverbType { none, hall, room, church, stage }

class AudioEffectsService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;
  
  static double _bassBoost = 0.0;
  static double _pitch = 0.0;
  static double _speed = 1.0;
  static ReverbType _reverb = ReverbType.none;
  static bool _isEnabled = true;

  // Equalizer bands (simulated)
  static List<double> _equalizerBands = List.filled(10, 0.0);
  static bool _equalizerEnabled = true;

  static Future<void> initialize() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('audio_effects_enabled') ?? true;
    _bassBoost = prefs.getDouble('bass_boost') ?? 0.0;
    _pitch = prefs.getDouble('pitch') ?? 0.0;
    _speed = prefs.getDouble('speed') ?? 1.0;
    final reverbIndex = prefs.getInt('reverb_type') ?? 0;
    _reverb = ReverbType.values[reverbIndex.clamp(0, ReverbType.values.length - 1)];
    
    // Load equalizer settings
    _equalizerBands = List<double>.from(prefs.getStringList('equalizer_bands')?.map(double.parse).toList() ?? List.filled(10, 0.0));
    _equalizerEnabled = prefs.getBool('equalizer_enabled') ?? true;
    
    _initialized = true;
  }

  static Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_effects_enabled', _isEnabled);
    await prefs.setDouble('bass_boost', _bassBoost);
    await prefs.setDouble('pitch', _pitch);
    await prefs.setDouble('speed', _speed);
    await prefs.setInt('reverb_type', _reverb.index);
    await prefs.setStringList('equalizer_bands', _equalizerBands.map((e) => e.toString()).toList());
    await prefs.setBool('equalizer_enabled', _equalizerEnabled);
  }

  static double get bassBoost => _bassBoost;
  static double get pitch => _pitch;
  static double get speed => _speed;
  static ReverbType get reverb => _reverb;
  static bool get isEnabled => _isEnabled;
  static List<double> get equalizerBands => List.unmodifiable(_equalizerBands);
  static bool get equalizerEnabled => _equalizerEnabled;

  static void setBassBoost(double value) {
    _bassBoost = value.clamp(0.0, 1.0);
    _applyEffects();
    savePreferences();
  }

  static void setPitch(double value) {
    _pitch = value.clamp(-12.0, 12.0);
    _applyEffects();
    savePreferences();
  }

  static void setSpeed(double value) {
    _speed = value.clamp(0.5, 2.0);
    _applyEffects();
    savePreferences();
  }

  static void setReverb(ReverbType type) {
    _reverb = type;
    _applyEffects();
    savePreferences();
  }

  static void toggleEnabled(bool value) {
    _isEnabled = value;
    _applyEffects();
    savePreferences();
  }

  static void setEqualizerBand(int index, double value) {
    if (index >= 0 && index < _equalizerBands.length) {
      _equalizerBands[index] = value.clamp(-12.0, 12.0);
      _applyEffects();
      savePreferences();
    }
  }

  static void toggleEqualizer(bool value) {
    _equalizerEnabled = value;
    _applyEffects();
    savePreferences();
  }

  static void resetEqualizer() {
    _equalizerBands = List.filled(10, 0.0);
    _equalizerEnabled = true;
    _applyEffects();
    savePreferences();
  }

  static void _applyEffects() {
    if (!_isEnabled || !_initialized) return;

    try {
      // Speed
      _player.setPlaybackRate(_speed);
      
      // Volume (Bass boost simulation)
      double volumeBoost = 1.0 + (_bassBoost * 0.3);
      
      // Equalizer - apply band boosts (simulated via volume adjustments)
      if (_equalizerEnabled) {
        // Calculate average boost from equalizer
        double avgBoost = _equalizerBands.reduce((a, b) => a + b) / _equalizerBands.length;
        // Convert dB to volume multiplier
        double eqMultiplier = 1.0 + (avgBoost / 24.0);
        _player.setVolume((volumeBoost * eqMultiplier).clamp(0.0, 2.0));
      } else {
        _player.setVolume(volumeBoost.clamp(0.0, 2.0));
      }

      // Reverb simulation
      switch (_reverb) {
        case ReverbType.hall:
          _player.setVolume((_player.volume * 0.85).clamp(0.0, 2.0));
          break;
        case ReverbType.room:
          _player.setVolume((_player.volume * 0.90).clamp(0.0, 2.0));
          break;
        case ReverbType.church:
          _player.setVolume((_player.volume * 0.80).clamp(0.0, 2.0));
          break;
        case ReverbType.stage:
          _player.setVolume((_player.volume * 0.88).clamp(0.0, 2.0));
          break;
        case ReverbType.none:
          break;
      }
    } catch (e) {
      print("Error applying effects: $e");
    }
  }

  static Future<void> resetAll() async {
    _bassBoost = 0.0;
    _pitch = 0.0;
    _speed = 1.0;
    _reverb = ReverbType.none;
    _isEnabled = true;
    _equalizerBands = List.filled(10, 0.0);
    _equalizerEnabled = true;
    _player.setVolume(1.0);
    _player.setPlaybackRate(1.0);
    await savePreferences();
  }

  static String getReverbName(ReverbType type) {
    switch (type) {
      case ReverbType.none: return 'None';
      case ReverbType.hall: return 'Hall';
      case ReverbType.room: return 'Room';
      case ReverbType.church: return 'Church';
      case ReverbType.stage: return 'Stage';
    }
  }

  static Future<void> applyToPlayer(AudioPlayer player) async {
    if (!_isEnabled || !_initialized) return;
    
    try {
      player.setPlaybackRate(_speed);
      double volumeBoost = 1.0 + (_bassBoost * 0.3);
      
      if (_equalizerEnabled) {
        double avgBoost = _equalizerBands.reduce((a, b) => a + b) / _equalizerBands.length;
        double eqMultiplier = 1.0 + (avgBoost / 24.0);
        player.setVolume((volumeBoost * eqMultiplier).clamp(0.0, 2.0));
      } else {
        player.setVolume(volumeBoost.clamp(0.0, 2.0));
      }
    } catch (e) {
      print("Error applying to player: $e");
    }
  }
}
