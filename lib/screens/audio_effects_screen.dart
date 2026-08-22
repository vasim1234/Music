import 'package:flutter/material.dart';
import '../services/audio_effects_service.dart';

class AudioEffectsScreen extends StatefulWidget {
  const AudioEffectsScreen({super.key});

  @override
  State<AudioEffectsScreen> createState() => _AudioEffectsScreenState();
}

class _AudioEffectsScreenState extends State<AudioEffectsScreen> {
  late bool _isEnabled;
  late double _bassBoost;
  late double _pitch;
  late double _speed;
  late ReverbType _reverb;

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  void _loadValues() {
    _isEnabled = AudioEffectsService.isEnabled;
    _bassBoost = AudioEffectsService.bassBoost;
    _pitch = AudioEffectsService.pitch;
    _speed = AudioEffectsService.speed;
    _reverb = AudioEffectsService.reverb;
  }

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
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 20),

            // Bass Boost
            _buildSlider(
              icon: Icons.equalizer,
              title: 'Bass Boost',
              value: _bassBoost,
              displayValue: '${(_bassBoost * 100).round()}%',
              onChanged: (v) {
                setState(() {
                  _bassBoost = v;
                  AudioEffectsService.setBassBoost(v);
                });
              },
            ),

            // Pitch Control
            _buildSlider(
              icon: Icons.tune,
              title: 'Pitch',
              value: (_pitch + 12) / 24,
              displayValue: '${_pitch.round()} semitones',
              onChanged: (v) {
                double pitch = (v * 24) - 12;
                setState(() {
                  _pitch = pitch;
                  AudioEffectsService.setPitch(pitch);
                });
              },
            ),

            // Speed Control
            _buildSlider(
              icon: Icons.speed,
              title: 'Speed',
              value: (_speed - 0.5) / 1.5,
              displayValue: '${_speed.toStringAsFixed(1)}x',
              onChanged: (v) {
                double speed = (v * 1.5) + 0.5;
                setState(() {
                  _speed = speed;
                  AudioEffectsService.setSpeed(speed);
                });
              },
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
                onPressed: () async {
                  await AudioEffectsService.resetAll();
                  setState(() {
                    _loadValues();
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All effects reset to default'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
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

  Widget _buildSlider({
    required IconData icon,
    required String title,
    required double value,
    required String displayValue,
    required ValueChanged<double> onChanged,
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
              Icon(icon, color: _isEnabled ? Colors.deepPurple : Colors.grey),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isEnabled ? Colors.black87 : Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _isEnabled ? Colors.deepPurple : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: _isEnabled ? Colors.deepPurple : Colors.grey.shade400,
              inactiveTrackColor: _isEnabled ? Colors.deepPurple.shade100 : Colors.grey.shade300,
              thumbColor: _isEnabled ? Colors.deepPurple : Colors.grey,
              overlayColor: _isEnabled ? Colors.deepPurple.withOpacity(0.2) : Colors.transparent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: _isEnabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}
