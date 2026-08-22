#!/bin/bash

# Check if Lyrics exists
if grep -q "Lyrics" lib/screens/home_screen.dart; then
    echo "✅ Lyrics already exists"
else
    # Add missing items after Scan Music
    sed -i '/ListTile.*Scan Music/a \
              const Divider(),\
              // 🎵 LYRICS - NEW!\
              ListTile(\
                leading: const Icon(Icons.lyrics, color: Colors.pink),\
                title: const Text("Lyrics", style: TextStyle(fontWeight: FontWeight.w600)),\
                onTap: () {\
                  Navigator.pop(context);\
                  if (_currentIndex >= 0 && _visibleSongs.isNotEmpty) {\
                    String songName = fileName(_visibleSongs[_currentIndex].path);\
                    Navigator.push(\
                      context,\
                      MaterialPageRoute(\
                        builder: (context) => LyricsScreen(\
                          songName: songName,\
                          artist: "Local Audio",\
                        ),\
                      ),\
                    );\
                  } else {\
                    ScaffoldMessenger.of(context).showSnackBar(\
                      const SnackBar(content: Text("Play a song first!")),\
                    );\
                  }\
                },\
              ),\
              // 📊 VISUALIZER - NEW!\
              ListTile(\
                leading: const Icon(Icons.equalizer, color: Colors.orange),\
                title: const Text("Visualizer", style: TextStyle(fontWeight: FontWeight.w600)),\
                onTap: () {\
                  Navigator.pop(context);\
                  _showVisualizer();\
                },\
              ),\
              // 🎚️ AUDIO EFFECTS - NEW!\
              ListTile(\
                leading: const Icon(Icons.audiotrack, color: Colors.teal),\
                title: const Text("Audio Effects", style: TextStyle(fontWeight: FontWeight.w600)),\
                onTap: () {\
                  Navigator.pop(context);\
                  Navigator.push(\
                    context,\
                    MaterialPageRoute(builder: (context) => const AudioEffectsScreen()),\
                  );\
                },\
              ),' lib/screens/home_screen.dart
    echo "✅ Missing drawer items added!"
fi
