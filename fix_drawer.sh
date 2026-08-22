#!/bin/bash

# Check if drawer items already exist
if grep -q "Lyrics" lib/screens/home_screen.dart; then
    echo "✅ Lyrics already in drawer"
else
    # Add missing drawer items
    sed -i '/ListTile.*Equalizer/i \
              // 🎵 LYRICS - NEW!\n\
              ListTile(\n\
                leading: const Icon(Icons.lyrics, color: Colors.pink),\n\
                title: const Text("Lyrics", style: TextStyle(fontWeight: FontWeight.w600)),\n\
                onTap: () {\n\
                  Navigator.pop(context);\n\
                  if (_currentIndex >= 0 && _visibleSongs.isNotEmpty) {\n\
                    String songName = fileName(_visibleSongs[_currentIndex].path);\n\
                    Navigator.push(\n\
                      context,\n\
                      MaterialPageRoute(\n\
                        builder: (context) => LyricsScreen(\n\
                          songName: songName,\n\
                          artist: "Local Audio",\n\
                        ),\n\
                      ),\n\
                    );\n\
                  } else {\n\
                    ScaffoldMessenger.of(context).showSnackBar(\n\
                      const SnackBar(content: Text("Play a song first!")),\n\
                    );\n\
                  }\n\
                },\n\
              ),\n\
              // 📊 VISUALIZER - NEW!\n\
              ListTile(\n\
                leading: const Icon(Icons.equalizer, color: Colors.orange),\n\
                title: const Text("Visualizer", style: TextStyle(fontWeight: FontWeight.w600)),\n\
                onTap: () {\n\
                  Navigator.pop(context);\n\
                  _showVisualizer();\n\
                },\n\
              ),\n\
              // 🎚️ AUDIO EFFECTS - NEW!\n\
              ListTile(\n\
                leading: const Icon(Icons.audiotrack, color: Colors.teal),\n\
                title: const Text("Audio Effects", style: TextStyle(fontWeight: FontWeight.w600)),\n\
                onTap: () {\n\
                  Navigator.pop(context);\n\
                  Navigator.push(\n\
                    context,\n\
                    MaterialPageRoute(builder: (context) => const AudioEffectsScreen()),\n\
                  );\n\
                },\n\
              ),' lib/screens/home_screen.dart
    echo "✅ Drawer items added!"
fi
