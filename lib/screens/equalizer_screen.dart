import 'package:flutter/material.dart';
import '../services/audio_effects_service.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({Key? key}) : super(key: key);

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  late List<double> _bandValues;
  final List<String> _bandLabels = ['32', '64', '125', '250', '500', '1k', '2k', '4k', '8k', '16k'];
  bool _isEqualizerOn = true;
  int _selectedPreset = 0;

  final List<Map<String, dynamic>> _presets = [
    {'name': 'Normal', 'values': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]},
    {'name': 'Bass Booster', 'values': [4.0, 6.0, 6.0, 4.0, 2.0, 0.0, -2.0, -4.0, -4.0, -6.0]},
    {'name': 'Treble Booster', 'values': [-4.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0, 6.0, 4.0, 4.0]},
    {'name': 'Vocal', 'values': [-2.0, -2.0, -2.0, 0.0, 2.0, 4.0, 4.0, 2.0, 0.0, -2.0]},
    {'name': 'Rock', 'values': [4.0, 4.0, 2.0, 0.0, -2.0, -4.0, -2.0, 2.0, 4.0, 4.0]},
    {'name': 'Pop', 'values': [-2.0, -2.0, 0.0, 2.0, 4.0, 4.0, 2.0, 0.0, -2.0, -2.0]},
    {'name': 'Classical', 'values': [4.0, 4.0, 2.0, 0.0, 0.0, 0.0, 0.0, 2.0, 4.0, 4.0]},
    {'name': 'Jazz', 'values': [2.0, 2.0, 2.0, 0.0, 0.0, 0.0, 0.0, 2.0, 4.0, 4.0]},
    {'name': 'Custom', 'values': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]},
  ];

  @override
  void initState() {
    super.initState();
    AudioEffectsService.initialize();
    _bandValues = List<double>.from(AudioEffectsService.equalizerBands);
    _isEqualizerOn = AudioEffectsService.equalizerEnabled;
  }

  void _applyEqualizer() {
    for (int i = 0; i < _bandValues.length; i++) {
      AudioEffectsService.setEqualizerBand(i, _bandValues[i]);
    }
    AudioEffectsService.toggleEqualizer(_isEqualizerOn);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Equalizer Applied!'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetEqualizer() {
    setState(() {
      _bandValues = List.filled(10, 0.0);
      _selectedPreset = 0;
      _isEqualizerOn = true;
    });
    AudioEffectsService.resetEqualizer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Equalizer Reset!'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Equalizer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEqualizerOn ? Icons.equalizer : Icons.equalizer_outlined),
            onPressed: () {
              setState(() => _isEqualizerOn = !_isEqualizerOn);
              _applyEqualizer();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Presets
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Presets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presets.length,
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedPreset == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPreset = index;
                            if (index < _presets.length - 1) {
                              _bandValues = List<double>.from(_presets[index]['values']);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _presets[index]['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Equalizer Bands
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: Column(
                children: [
                  const Text('Frequency (Hz)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 15),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(10, (index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: _buildBandSlider(index),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      Text('+12 dB', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text('0', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text('-12 dB', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _resetEqualizer,
                        icon: const Icon(Icons.restore, size: 20),
                        label: const Text('Reset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _applyEqualizer,
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text('Apply'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isEqualizerOn ? Colors.green.shade50 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isEqualizerOn ? Icons.check_circle : Icons.power_off,
                          color: _isEqualizerOn ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isEqualizerOn ? 'Equalizer Active' : 'Equalizer Disabled',
                          style: TextStyle(
                            color: _isEqualizerOn ? Colors.green : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBandSlider(int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotatedBox(
          quarterTurns: 3,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, disabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: _isEqualizerOn
                  ? (_bandValues[index] >= 0 ? Colors.deepPurple : Colors.deepPurple.shade300)
                  : Colors.grey.shade400,
              inactiveTrackColor: _isEqualizerOn ? Colors.deepPurple.shade100 : Colors.grey.shade300,
              thumbColor: _isEqualizerOn ? Colors.deepPurple : Colors.grey,
              overlayColor: _isEqualizerOn ? Colors.deepPurple.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
            ),
            child: SizedBox(
              width: 150,
              child: Slider(
                value: _bandValues[index].clamp(-12.0, 12.0),
                min: -12,
                max: 12,
                divisions: 24,
                onChanged: _isEqualizerOn
                    ? (value) {
                        setState(() {
                          _bandValues[index] = value;
                          _selectedPreset = _presets.length - 1;
                        });
                      }
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _bandLabels[index],
          style: TextStyle(
            fontSize: 12,
            color: _isEqualizerOn ? Colors.black87 : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_bandValues[index].round()}dB',
          style: TextStyle(
            fontSize: 9,
            color: _isEqualizerOn ? Colors.deepPurple : Colors.grey,
          ),
        ),
      ],
    );
  }
}
