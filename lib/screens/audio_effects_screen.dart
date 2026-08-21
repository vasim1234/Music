import 'package:flutter/material.dart';
import '../services/audio_effects_service.dart';

class AudioEffectsScreen extends StatefulWidget {
  const AudioEffectsScreen({super.key});

  @override
  State<AudioEffectsScreen> createState() => _AudioEffectsScreenState();
}

class _AudioEffectsScreenState extends State<AudioEffectsScreen> {
  bool _isEnabled = AudioEffectsService.isEnabled;
  double _bassBoost = AudioEffectsService.bassBoost;
  double _pitch = AudioEffectsService.pitch;
  double _speed = AudioEffectsService.speed;
  ReverbType _reverb = AudioEffectsService.reverb;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Effects', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() {
                _isEnabled = !_isEnabled;
                AudioEffectsService.toggleEnabled(_isEnabled);
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isEnabled ? Colors.green.shade50 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _isEnabled ? Colors.green : Colors.grey,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEnabled ? Icons.check_circle : Icons.power_off,
                    color: _isEnabled ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEnabled ? 'Audio Effects Active' : 'Audio Effects Disabled',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isEnabled ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bass Boost
            _buildSliderCard(
              icon: Icons.bass_boost,
              title: 'Bass Boost',
              subtitle: '${(_bassBoost * 100).round()}%',
              value: _bassBoost,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              enabled: _isEnabled,
              onChanged: (value) {
                setState(() {
                  _bassBoost = value;
                  AudioEffectsService.setBassBoost(value);
                });
              },
            ),

            // Pitch Control
            _buildSliderCard(
              icon: Icons.tune,
              title: 'Pitch Control',
              subtitle: '${_pitch.round()} semitones',
              value: (_pitch + 12) / 24,
              min: -12,
              max: 12,
              divisions: 24,
              enabled: _isEnabled,
              onChanged: (value) {
                double pitch = (value * 24) - 12;
                setState(() {
                  _pitch = pitch;
                  AudioEffectsService.setPitch(pitch);
                });
              },
              displayValue: '${_pitch.round()}',
            ),

            // Speed Control
            _buildSliderCard(
              icon: Icons.speed,
              title: 'Playback Speed',
              subtitle: '${_speed.toStringAsFixed(1)}x',
              value: (_speed - 0.5) / 1.5,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              enabled: _isEnabled,
              onChanged: (value) {
                double speed = (value * 1.5) + 0.5;
                setState(() {
                  _speed = speed;
                  AudioEffectsService.setSpeed(speed);
                });
              },
              displayValue: '${_speed.toStringAsFixed(1)}x',
            ),

            // Reverb
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.surround_sound, color: _isEnabled ? Colors.deepPurple : Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        'Reverb',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isEnabled ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AudioEffectsService.getReverbName(_reverb),
                        style: TextStyle(
                          fontSize: 14,
                          color: _isEnabled ? Colors.deepPurple : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ReverbType.values.map((type) {
                      bool isSelected = _reverb == type;
                      return FilterChip(
                        label: Text(AudioEffectsService.getReverbName(type)),
                        selected: isSelected,
                        onSelected: _isEnabled ? (selected) {
                          setState(() {
                            _reverb = type;
                            AudioEffectsService.setReverb(type);
                          });
                        } : null,
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        selectedColor: Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Reset Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    AudioEffectsService.resetAll();
                    _bassBoost = 0.0;
                    _pitch = 0.0;
                    _speed = 1.0;
                    _reverb = ReverbType.none;
                    _isEnabled = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All effects reset to default'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.restore),
                label: const Text('Reset All Effects', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required bool enabled,
    required ValueChanged<double> onChanged,
    String? displayValue,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: enabled ? Colors.deepPurple : Colors.grey),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: enabled ? Colors.black87 : Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                displayValue ?? subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: enabled ? Colors.deepPurple : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: enabled ? Colors.deepPurple : Colors.grey.shade400,
              inactiveTrackColor: enabled ? Colors.deepPurple.shade100 : Colors.grey.shade300,
              thumbColor: enabled ? Colors.deepPurple : Colors.grey,
              overlayColor: enabled ? Colors.deepPurple.withOpacity(0.2) : Colors.transparent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              divisions: divisions,
              onChanged: enabled ? onChanged : null,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                min.toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
              Text(
                max.toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
