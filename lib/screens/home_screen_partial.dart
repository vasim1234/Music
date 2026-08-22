// Yeh sirf drawer section hai - isko home_screen.dart ke drawer mein replace karo

drawer: Drawer(
  backgroundColor: Colors.white,
  child: Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFFD946EF)], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.headphones, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 15),
            const Text('Bhai Bhai App', 
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 5),
            Text('${_playlist.length} Local Tracks', 
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Folder Management
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.deepPurple),
              title: const Text('Choose Folders', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                openFolderManager();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blueAccent),
              title: const Text('Scan Music', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                updatePlaylistFromFolders();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scanning...')),
                );
              },
            ),
            const Divider(),
            
            // 🎵 LYRICS - NEW!
            ListTile(
              leading: const Icon(Icons.lyrics, color: Colors.pink),
              title: const Text('Lyrics', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                if (_currentIndex >= 0 && _filteredPlaylist.isNotEmpty) {
                  String songName = getFileName(_filteredPlaylist[_currentIndex].path);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LyricsScreen(
                        songName: songName,
                        artist: 'Local Audio',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Play a song first!')),
                  );
                }
              },
            ),
            
            // 📊 VISUALIZER - NEW!
            ListTile(
              leading: const Icon(Icons.equalizer, color: Colors.orange),
              title: const Text('Visualizer', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _showVisualizer();
              },
            ),
            
            // 🎚️ AUDIO EFFECTS - NEW!
            ListTile(
              leading: const Icon(Icons.audiotrack, color: Colors.teal),
              title: const Text('Audio Effects', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AudioEffectsScreen()),
                );
              },
            ),
            
            // Equalizer
            ListTile(
              leading: const Icon(Icons.equalizer, color: Colors.purple),
              title: const Text('Equalizer', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EqualizerScreen()),
                );
              },
            ),
            
            const Divider(),
            
            // Themes
            ListTile(
              leading: const Icon(Icons.palette, color: Colors.pink),
              title: const Text('Themes', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Themes Coming Soon! 🎨')),
                );
              },
            ),
            
            const Divider(),
            
            // Settings
            ListTile(
              leading: Icon(Icons.settings, color: Colors.grey.shade700),
              title: const Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('Share App'),
              onTap: () {},
            ),
          ],
        ),
      ),
      const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "Version 1.0.0\nMade with ❤️ by Bhai Bhai",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      )
    ],
  ),
),
