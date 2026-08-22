import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class VisualizerService {
  static final List<double> _bands = List.filled(16, 0.0);
  static Timer? _timer;
  static bool _isRunning = false;
  static final Random _random = Random();
  static AudioPlayer? _currentPlayer;

  static void start(AudioPlayer player) {
    if (_isRunning) return;
    _currentPlayer = player;
    _isRunning = true;
    
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _updateBands();
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _bands.fillRange(0, _bands.length, 0.0);
    _currentPlayer = null;
  }

  static void _updateBands() {
    // Simulate audio visualizer with smooth animation
    for (int i = 0; i < _bands.length; i++) {
      // Create wave-like patterns
      double time = DateTime.now().millisecondsSinceEpoch / 1000;
      double baseValue = sin(time * 2.0 + i * 0.5) * 0.3 + 0.5;
      double randomValue = _random.nextDouble() * 0.3;
      double peakValue = sin(time * 1.5 + i * 0.7).abs() * 0.4;
      
      // Combine for dynamic effect
      double value = (baseValue * 0.4 + randomValue * 0.3 + peakValue * 0.3);
      
      // Smooth transition
      _bands[i] = _bands[i] + (value - _bands[i]) * 0.3;
      _bands[i] = _bands[i].clamp(0.0, 1.0);
    }
  }

  static List<double> get bands => List.unmodifiable(_bands);
  static bool get isRunning => _isRunning;
}
