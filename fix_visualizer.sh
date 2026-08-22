#!/bin/bash

# Pehle backup lo
cp lib/screens/home_screen.dart lib/screens/home_screen_backup.dart

# Function ko class ke andar shift karo
sed -i '/^  void _showVisualizer()/,/^  }$/d' lib/screens/home_screen.dart

# Function ko sahi jagah insert karo (dispose se pehle)
sed -i '/^  @override/i \
  void _showVisualizer() {\
    if (_currentIndex < 0 || _visibleSongs.isEmpty) {\
      ScaffoldMessenger.of(context).showSnackBar(\
        const SnackBar(content: Text("Play a song first!")),\
      );\
      return;\
    }\
    VisualizerService.start(_player);\
    showDialog(\
      context: context,\
      barrierDismissible: true,\
      builder: (context) => Dialog(\
        backgroundColor: Colors.transparent,\
        child: Container(\
          height: 250,\
          padding: const EdgeInsets.all(20),\
          decoration: BoxDecoration(\
            color: Colors.black87,\
            borderRadius: BorderRadius.circular(20),\
          ),\
          child: Column(\
            children: [\
              const Text(\
                "Audio Visualizer",\
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),\
              ),\
              const SizedBox(height: 10),\
              const Text(\
                "Visualizing:",\
                style: TextStyle(color: Colors.white54, fontSize: 12),\
              ),\
              Text(\
                fileName(_visibleSongs[_currentIndex].path),\
                style: const TextStyle(color: Colors.white70, fontSize: 14),\
                maxLines: 1,\
                overflow: TextOverflow.ellipsis,\
              ),\
              const SizedBox(height: 20),\
              AudioVisualizer(\
                barCount: 20,\
                color: Colors.deepPurpleAccent,\
                height: 100,\
                animate: true,\
              ),\
              const SizedBox(height: 20),\
              TextButton(\
                onPressed: () {\
                  VisualizerService.stop();\
                  Navigator.pop(context);\
                },\
                child: const Text(\
                  "Close",\
                  style: TextStyle(color: Colors.white),\
                ),\
              ),\
            ],\
          ),\
        ),\
      ),\
    ).then((_) {\
      VisualizerService.stop();\
    });\
  }' lib/screens/home_screen.dart

echo "✅ Visualizer function fixed!"
