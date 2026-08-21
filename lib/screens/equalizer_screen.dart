import 'package:flutter/material.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  final List<double> _bands = List.filled(10, 0.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('10 Band Equalizer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, i) {
                  return Row(
                    children: [
                      SizedBox(width: 40, child: Text('${i * 60}Hz', style: const TextStyle(fontSize: 12))),
                      Expanded(
                        child: Slider(
                          value: _bands[i],
                          min: -10,
                          max: 10,
                          divisions: 20,
                          onChanged: (v) => setState(() => _bands[i] = v),
                        ),
                      ),
                      SizedBox(width: 40, child: Text('${_bands[i].round()}dB', style: const TextStyle(fontSize: 12))),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton.icon(
                  onPressed: () => setState(() => _bands.fillRange(0, _bands.length, 0.0)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
