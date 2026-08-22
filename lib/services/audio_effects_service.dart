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

  static Future<void> initialize() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('audio_effects_enabled') ?? true;
    _bassBoost = prefs.getDouble('bass_boost') ?? 0.0;
    _pitch = prefs.getDouble('pitch') ?? 0.0;
    _speed = prefs.getDouble('speed') ?? 1.0;
    final reverbIndex = prefs.getInt('reverb_type') ?? 0;
    _reverb = ReverbType.values[reverbIndex.clamp(0, ReverbType.values.length - 1)];
    
    _initialized = true;
  }

  static Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_effects_enabled', _isEnabled);
    await prefs.setDouble('bass_boost', _bassBoost);
    await prefs.setDouble('pitch', _pitch);
    await prefs.setDouble('speed', _speed);
    await prefs.setInt('reverb_type', _reverb.index);
  }

  static double get bassBoost => _bassBoost;
  static double get pitch => _pitch;
  static double get speed => _speed;
  static ReverbType get reverb => _reverb;
  static bool get isEnabled => _isEnabled;

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

  static void _applyEffects() {
    if (!_isEnabled || !_initialized) return;

    try {
      _player.setPlaybackRate(_speed);
      
      double volumeBoost = 1.0 + (_bassBoost * 0.3);
      _player.setVolume(volumeBoost.clamp(0.0, 2.0));

      // Reverb simulation
      switch (_reverb) {
        case ReverbType.hall:
          _player.setVolume((volumeBoost * 0.85).clamp(0.0, 2.0));
          break;
        case ReverbType.room:
          _player.setVolume((volumeBoost * 0.90).clamp(0.0, 2.0));
          break;
        case ReverbType.church:
          _player.setVolume((volumeBoost * 0.80).clamp(0.0, 2.0));
          break;
        case ReverbType.stage:
          _player.setVolume((volumeBoost * 0.88).clamp(0.0, 2.0));
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
      player.setVolume(volumeBoost.clamp(0.0, 2.0));
    } catch (e) {
      print("Error applying to player: $e");
    }
  }
}
