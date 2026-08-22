import 'package:flutter/material.dart';
import '../services/fm_radio_service.dart';

class FMRadioScreen extends StatefulWidget {
  const FMRadioScreen({super.key});

  @override
  State<FMRadioScreen> createState() => _FMRadioScreenState();
}

class _FMRadioScreenState extends State<FMRadioScreen> {
  String? _playingStation;
  bool _isPlaying = false;
  double _volume = 0.8;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _isPlaying = FMRadioService.isPlaying;
    _playingStation = FMRadioService.currentStationName;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stations = _searchQuery.isEmpty 
        ? FMRadioService.stations 
        : FMRadioService.stations
            .where((s) => s['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FM Radio', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search stations...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Now Playing
          if (_isPlaying && _playingStation != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.purple.shade700],
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.radio, color: Colors.white, size: 60),
                  const SizedBox(height: 10),
                  Text(
                    '🎵 Now Playing',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    _playingStation!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.stop, color: Colors.white),
                        onPressed: () async {
                          await FMRadioService.stop();
                          setState(() {
                            _isPlaying = false;
                            _playingStation = null;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: () {
                          if (_isPlaying) {
                            FMRadioService.stop();
                            setState(() => _isPlaying = false);
                          } else if (_playingStation != null) {
                            _playStation(_playingStation!);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.volume_up, color: Colors.white, size: 20),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0,
                          max: 1,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white30,
                          onChanged: (v) {
                            setState(() => _volume = v);
                            FMRadioService.setVolume(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Station List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];
                final isActive = _playingStation == station['name'] && _isPlaying;
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isActive ? 4 : 1,
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.blue.shade100 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          station['icon'],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    title: Text(
                      station['name'],
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? Colors.blue.shade700 : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      station['city'],
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isActive
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.play_circle, color: Colors.blue, size: 32),
                            onPressed: () => _playStation(station['name']),
                          ),
                    onTap: () => _playStation(station['name']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _playStation(String name) async {
    final station = FMRadioService.stations.firstWhere(
      (s) => s['name'] == name,
      orElse: () => {},
    );
    
    if (station.isEmpty) return;

    await FMRadioService.playStation(
      station['name'],
      station['url'],
    );

    setState(() {
      _playingStation = station['name'];
      _isPlaying = FMRadioService.isPlaying;
    });
  }

  @override
  void dispose() {
    FMRadioService.dispose();
    super.dispose();
  }
}
