import 'package:just_audio/just_audio.dart';

class FMRadioService {
  static final AudioPlayer _player = AudioPlayer();
  static String? _currentStationUrl;
  static bool _isPlaying = false;
  static String _currentStationName = '';

  static final List<Map<String, dynamic>> _stations = [
    {
      'name': 'Radio City 91.1',
      'url': 'https://stream.radiostreamlive.com/radiocity',
      'city': 'Mumbai',
      'icon': '🎵'
    },
    {
      'name': 'Red FM 93.5',
      'url': 'https://stream.radiostreamlive.com/redfm',
      'city': 'Delhi',
      'icon': '🔴'
    },
    {
      'name': 'Radio Mirchi 98.3',
      'url': 'https://stream.radiostreamlive.com/mirchi',
      'city': 'Mumbai',
      'icon': '💖'
    },
    {
      'name': 'Vividh Bharati',
      'url': 'https://stream.radiostreamlive.com/vividh',
      'city': 'All India',
      'icon': '🇮🇳'
    },
    {
      'name': 'AIR FM Gold',
      'url': 'https://stream.radiostreamlive.com/airgold',
      'city': 'Delhi',
      'icon': '⭐'
    },
    {
      'name': 'Radio One 94.3',
      'url': 'https://stream.radiostreamlive.com/radioone',
      'city': 'Mumbai',
      'icon': '🎶'
    },
    {
      'name': 'Big FM 92.7',
      'url': 'https://stream.radiostreamlive.com/bigfm',
      'city': 'Mumbai',
      'icon': '📻'
    },
    {
      'name': ' Fever FM 104.0',
      'url': 'https://stream.radiostreamlive.com/fever',
      'city': 'Delhi',
      'icon': '🔥'
    },
  ];

  static List<Map<String, dynamic>> get stations => _stations;
  static bool get isPlaying => _isPlaying;
  static String get currentStationName => _currentStationName;

  static Future<void> playStation(String name, String url) async {
    try {
      if (_isPlaying) {
        await _player.stop();
        _isPlaying = false;
      }
      
      _currentStationName = name;
      _currentStationUrl = url;
      
      await _player.setUrl(url);
      await _player.play();
      _isPlaying = true;
    } catch (e) {
      print("Error playing station: $e");
      _isPlaying = false;
    }
  }

  static Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentStationName = '';
  }

  static void dispose() {
    _player.dispose();
  }

  static void setVolume(double volume) {
    _player.setVolume(volume);
  }
}
