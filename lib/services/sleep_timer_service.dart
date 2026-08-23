import 'dart:async';

class SleepTimerService {
  static Timer? _timer;
  static int _remainingSeconds = 0;
  static int _totalSeconds = 0;
  static bool _isRunning = false;
  static Function? _onComplete;

  static void initialize(Function onComplete) {
    _onComplete = onComplete;
  }

  static void start(int seconds, {Function? onTick}) {
    stop();
    
    _totalSeconds = seconds;
    _remainingSeconds = seconds;
    _isRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      
      if (_remainingSeconds <= 0) {
        stop();
        _onComplete?.call();
      }
      onTick?.call();
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _remainingSeconds = 0;
  }

  static void pause() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  static void resume() {
    if (_remainingSeconds > 0 && !_isRunning) {
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          stop();
          _onComplete?.call();
        }
      });
    }
  }

  static void extend(int seconds) {
    if (_isRunning || _remainingSeconds > 0) {
      _remainingSeconds += seconds;
      _totalSeconds += seconds;
    }
  }

  static int get remainingSeconds => _remainingSeconds;
  static bool get isRunning => _isRunning;
  static double get progress => _totalSeconds > 0 
      ? (_totalSeconds - _remainingSeconds) / _totalSeconds 
      : 0.0;

  static String get formattedTime {
    final int minutes = _remainingSeconds ~/ 60;
    final int seconds = _remainingSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }
}
