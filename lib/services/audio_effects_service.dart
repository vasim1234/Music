import 'package:just_audio/just_audio.dart';

enum ReverbType { none, smallRoom, largeHall, cathedral, plate }

class AudioEffectsService {
  static bool _isEnabled = true;
  static double _bassBoost = 0.0;
  static double _pitch = 0.0;
  static double _speed = 1.0;
  static ReverbType _reverb = ReverbType.none;

  // Getters
  static bool get isEnabled => _isEnabled;
  static double get bassBoost => _bassBoost;
  static double get pitch => _pitch;
  static double get speed => _speed;
  static ReverbType get reverb => _reverb;

  static void toggleEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  static void setBassBoost(double value) {
    _bassBoost = value;
  }

  static void setPitch(double value) {
    _pitch = value;
  }

  static void setSpeed(double value) {
    _speed = value;
  }

  static void setReverb(ReverbType type) {
    _reverb = type;
  }

  static String getReverbName(ReverbType type) {
    switch (type) {
      case ReverbType.none:
        return 'None';
      case ReverbType.smallRoom:
        return 'Small Room';
      case ReverbType.largeHall:
        return 'Large Hall';
      case ReverbType.cathedral:
        return 'Cathedral';
      case ReverbType.plate:
        return 'Plate';
    }
  }

  static Future<void> resetAll() async {
    _isEnabled = true;
    _bassBoost = 0.0;
    _pitch = 0.0;
    _speed = 1.0;
    _reverb = ReverbType.none;
  }
}
