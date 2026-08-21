import 'package:flutter/material.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});
  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  final labels = const ['32', '64', '125', '250', '500', '1k', '2k', '4k', '8k', '16k'];
  final presets = const <String, List<double>>{
    'Normal': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    'Bass Booster': [5, 6, 5, 3, 1, 0, -1, -2, -3, -3],
    'Treble Booster': [-3, -3, -2, 0, 2, 4, 5, 6, 5, 4],
    'Vocal': [-2, -2, -1, 1, 3, 4, 3, 1, 0, -1],
    'Rock': [4, 4, 2, 0, -2, -2, 0, 3, 4, 4],
    'Pop': [-2, -1, 1, 3, 4, 3, 1, 0, -1, -2],
    'Classical': [4, 3, 2, 0, 0, 0, 0, 2, 3, 4],
  };
  late List<double> values;
  bool enabled = true;
  String selected = 'Normal';

  @override
  void initState() { super.initState(); values = List<double>.from(presets['Normal']!); }
  void selectPreset(String name) { setState(() { selected = name; values = List<double>.from(presets[name]!); }); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equalizer'), actions: [Switch(value: enabled, onChanged: (v) => setState(() => enabled = v))]),
      body: Column(
        children: [
          SizedBox(
            height: 62,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(10),
              children: presets.keys.map((name) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: Text(name), selected: selected == name, onSelected: (_) => selectPreset(name)),
              )).toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(values.length, (i) => Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: values[i].clamp(-12, 12), min: -12, max: 12, divisions: 24,
                          onChanged: enabled ? (v) => setState(() { values[i] = v; selected = 'Custom'; }) : null,
                        ),
                      ),
                    ),
                    Text(labels[i], style: const TextStyle(fontSize: 11)),
                    Text('${values[i].round()} dB', style: TextStyle(fontSize: 10, color: enabled ? Colors.deepPurple : Colors.grey)),
                    const SizedBox(height: 12),
                  ],
                ),
              )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equalizer settings saved for this session.'))),
              icon: const Icon(Icons.check), label: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}
