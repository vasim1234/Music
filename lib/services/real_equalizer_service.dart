import 'package:just_audio/just_audio.dart';
import 'package:android_equalizer/android_equalizer.dart';

class RealEqualizerService {
  static AndroidEqualizer? _equalizer;
  static int _audioSessionId = 0;
  static bool _isInitialized = false;
  static List<double> _bandLevels = List.filled(10, 0.0);
  static bool _isEnabled = true;

  static Future<void> initialize(AudioPlayer player) async {
    if (_isInitialized) return;
    
    try {
      _audioSessionId = await player.getAudioSessionId();
      _equalizer = AndroidEqualizer(_audioSessionId);
      await _equalizer?.setEnabled(true);
      
      // Get number of bands supported
      final bandCount = await _equalizer?.getNumberOfBands() ?? 5;
      print("Equalizer bands: $bandCount");
      
      _isInitialized = true;
    } catch (e) {
      print("Equalizer initialization failed: $e");
      _isInitialized = false;
    }
  }

  static Future<void> setBandLevel(int index, double level) async {
    if (!_isInitialized || _equalizer == null) return;
    if (index < 0 || index >= _bandLevels.length) return;

    try {
      // Convert -12 to +12 dB to millibels (-1200 to +1200)
      int millibels = (level * 100).round();
      await _equalizer?.setBandLevel(index, millibels);
      _bandLevels[index] = level;
    } catch (e) {
      print("Error setting band level: $e");
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (_equalizer != null) {
      await _equalizer?.setEnabled(enabled);
    }
  }

  static Future<void> reset() async {
    for (int i = 0; i < _bandLevels.length; i++) {
      await setBandLevel(i, 0.0);
    }
  }

  static void dispose() {
    _equalizer?.release();
    _equalizer = null;
    _isInitialized = false;
  }

  static bool get isInitialized => _isInitialized;
  static bool get isEnabled => _isEnabled;
  static List<double> get bandLevels => List.unmodifiable(_bandLevels);
}
