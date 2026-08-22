import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/album_art_service.dart'; // ✅ Album Art Service Imported!
import 'equalizer_screen.dart';
import 'lyrics_screen.dart';
import 'audio_effects_screen.dart';
import '../widgets/audio_visualizer.dart';
import '../services/visualizer_service.dart';
import 'fm_radio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _savedFolders = [];
  List<File> _playlist = []; 
  List<File> _filteredPlaylist = []; 
  List<String> _favorites = []; 
  List<String> _recentSongs = [];
  List<Map<String, dynamic>> _customPlaylists = [];
  String _selectedPlaylist = '';
  
  int _currentIndex = -1;
  bool isPlaying = false;
  bool _hasPermission = false;
  bool is3DOn = false;
  String _currentView = 'Songs';

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => isPlaying = state == PlayerState.playing);
      _updateLockScreenControls();
    });
    _player.onPlayerComplete.listen((event) => playNext());
    
    _loadData();
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _updateLockScreenControls();
    }
  }

  void _updateLockScreenControls() {
    if (_currentIndex >= 0 && _filteredPlaylist.isNotEmpty) {
      String songName = getFileName(_filteredPlaylist[_currentIndex].path);
      NotificationService.showNowPlayingNotification(
        title: songName,
        artist: "Bhai Bhai App",
        isPlaying: isPlaying,
      );
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? saved = prefs.getStringList('saved_folders');
    List<String>? favs = prefs.getStringList('favorites');
    List<String>? recent = prefs.getStringList('recent_songs');
    List<String>? playlists = prefs.getStringList('custom_playlists');
    
    if (favs != null) setState(() => _favorites = favs);
    if (recent != null) setState(() => _recentSongs = recent);
    
    if (playlists != null) {
      setState(() {
        _customPlaylists = playlists.map((p) {
          List<String> parts = p.split('|||');
          return {'name': parts[0], 'songs': parts.length > 1 ? parts[1].split(',').where((s) => s.isNotEmpty).toList() : []};
        }).toList();
      });
    }

    if (saved != null) {
      setState(() {
        _savedFolders = saved.map((path) => ({'name': path.split('/').last, 'path': path, 'isChecked': true})).toList();
      });
      await updatePlaylistFromFolders();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> paths = _savedFolders.map((f) => f['path'] as String).toList();
    await prefs.setStringList('saved_folders', paths);
    await prefs.setStringList('favorites', _favorites);
    await prefs.setStringList('recent_songs', _recentSongs);
    
    List<String> playlistData = _customPlaylists.map<String>((p) => p['name'].toString() + '|||' + (p['songs'] as List<String>).join(',')).toList();
    await prefs.setStringList('custom_playlists', playlistData);
  }

  void createNewPlaylist() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [Icon(Icons.playlist_add, color: Colors.deepPurple), SizedBox(width: 10), Text('Create Playlist')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(hintText: 'Enter playlist name', prefixIcon: const Icon(Icons.music_note), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.grey.shade50),
            ),
            const SizedBox(height: 10),
            const Text('Example: Gym, Safar, Romantic', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() { _customPlaylists.add({'name': nameController.text.trim(), 'songs': <String>[]}); });
                _saveData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Playlist "${nameController.text}" created!'), backgroundColor: Colors.green));
                setView('Playlists');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void addToPlaylist(String songPath) {
    if (_customPlaylists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('No playlists! Create one first.'), backgroundColor: Colors.orange, action: SnackBarAction(label: 'Create', textColor: Colors.white, onPressed: createNewPlaylist)));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Add to Playlist'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: _customPlaylists.map((playlist) {
                  bool isInPlaylist = (playlist['songs'] as List<String>).contains(songPath);
                  return ListTile(
                    leading: Icon(isInPlaylist ? Icons.check_circle : Icons.add_circle_outline, color: isInPlaylist ? Colors.green : Colors.grey),
                    title: Text(playlist['name']),
                    subtitle: Text('${(playlist['songs'] as List<String>).length} songs'),
                    onTap: () {
                      setStateDialog(() {
                        if (isInPlaylist) { (playlist['songs'] as List<String>).remove(songPath); } else { (playlist['songs'] as List<String>).add(songPath); }
                      });
                      setState(() {});
                      _saveData();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isInPlaylist ? 'Removed from ${playlist['name']}' : 'Added to ${playlist['name']}'), backgroundColor: isInPlaylist ? Colors.red : Colors.green));
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
          );
        },
      ),
    );
  }

  Future<void> _checkPermission() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      var storageStatus = await Permission.storage.status;
      var manageStatus = await Permission.manageExternalStorage.status;
      if (!storageStatus.isGranted && !manageStatus.isGranted) {
        await Permission.storage.request();
        await Permission.manageExternalStorage.request();
        await Permission.audio.request();
      }
      storageStatus = await Permission.storage.status;
      manageStatus = await Permission.manageExternalStorage.status;
      setState(() { _hasPermission = storageStatus.isGranted || manageStatus.isGranted; });
      _loadData();
    }
  }

  Future<List<File>> _getAudioFilesSafely(Directory dir) async {
    List<File> audioFiles = [];
    try {
      List<FileSystemEntity> entities = dir.listSync(recursive: false);
      for (FileSystemEntity entity in entities) {
        try {
          if (entity is File) {
            String path = entity.path.toLowerCase();
            if (path.endsWith('.mp3') || path.endsWith('.m4a') || path.endsWith('.wav') || path.endsWith('.aac') || path.endsWith('.ogg') || path.endsWith('.flac') || path.endsWith('.wma')) {
              audioFiles.add(entity);
            }
          } else if (entity is Directory) {
            if (!entity.path.split('/').last.startsWith('.')) { audioFiles.addAll(await _getAudioFilesSafely(entity)); }
          }
        } catch (e) {}
      }
    } catch (e) {}
    return audioFiles;
  }

  Future<void> updatePlaylistFromFolders() async {
    setState(() { _playlist = []; _filteredPlaylist = []; });
    List<File> newSongs = [];
    for (var folder in _savedFolders) {
      if (folder['isChecked'] == true) {
        Directory dir = Directory(folder['path']);
        if (dir.existsSync()) {
          List<File> foundSongs = await _getAudioFilesSafely(dir);
          newSongs.addAll(foundSongs);
        }
      }
    }
    setState(() {
      _playlist = newSongs;
      filterSearchResults(_searchController.text);
      if (_currentIndex >= _filteredPlaylist.length) {
        _currentIndex = -1;
        _player.stop();
        isPlaying = false;
      }
    });
  }

  void openFolderManager() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => FolderManagerScreen(folders: _savedFolders, onFoldersUpdated: () async { await _saveData(); await updatePlaylistFromFolders(); setState(() {}); })));
  }

  void toggle3D() {
    setState(() {
      is3DOn = !is3DOn;
      if (is3DOn) { _player.setVolume(0.8); _player.setBalance(0.5); } else { _player.setVolume(1.0); _player.setBalance(0.0); }
    });
  }

  Future<void> playSong(String path) async { 
    await _player.play(DeviceFileSource(path)); 
    addToRecent(path);
    _updateLockScreenControls();
  }
  
  void playNext() {
    if (_filteredPlaylist.isNotEmpty && _currentIndex < _filteredPlaylist.length - 1) {
      setState(() => _currentIndex++);
      playSong(_filteredPlaylist[_currentIndex].path);
    }
  }
  
  void playPrevious() {
    if (_filteredPlaylist.isNotEmpty && _currentIndex > 0) {
      setState(() => _currentIndex--);
      playSong(_filteredPlaylist[_currentIndex].path);
    }
  }

  String formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return twoDigits(d.inMinutes.remainder(60)) + ":" + twoDigits(d.inSeconds.remainder(60));
  }

  String getFileName(String path) {
    String name = path.split('/').last;
    name = name.replaceAll(RegExp(r'\.(mp3|m4a|wav|aac|ogg|flac|wma)$', caseSensitive: false), '');
    return name.replaceAll(RegExp(r'\(.*?\)'), '').replaceAll(RegExp(r'\[.*?\]'), '').replaceAll('_', ' ').replaceAll('-', ' ').trim();
  }

  void setView(String viewName) {
    setState(() { _currentView = viewName; _searchController.clear(); filterSearchResults(''); });
  }

  void filterSearchResults(String query) {
    setState(() {
      List<File> baseList = [];
      if (_currentView == 'Favorites') { baseList = _playlist.where((f) => _favorites.contains(f.path)).toList(); } 
      else if (_currentView == 'Recent') { baseList = _recentSongs.map((p) => File(p)).where((f) => f.existsSync()).toList(); } 
      else if (_currentView == 'PlaylistDetail') {
        var playlist = _customPlaylists.firstWhere((p) => p['name'] == _selectedPlaylist, orElse: () => {'name': '', 'songs': <String>[]});
        List<String> songPaths = (playlist['songs'] as List<String>);
        baseList = _playlist.where((f) => songPaths.contains(f.path)).toList();
      } else { baseList = _playlist; }
      if (query.isEmpty) { _filteredPlaylist = baseList; } else { _filteredPlaylist = baseList.where((f) => getFileName(f.path).toLowerCase().contains(query.toLowerCase())).toList(); }
    });
  }

  void toggleFavorite(String path) async {
    setState(() {
      if (_favorites.contains(path)) { _favorites.remove(path); } else { _favorites.add(path); }
      if (_currentView == 'Favorites') filterSearchResults(_searchController.text);
    });
    await _saveData();
  }

  Future<void> addToRecent(String path) async {
    setState(() {
      _recentSongs.remove(path);
      _recentSongs.insert(0, path);
      if (_recentSongs.length > 50) _recentSongs.removeLast();
    });
    await _saveData();
  }

  // ✅ Yahan Aapka Naya Album Art Add Hua Hai Full Screen Player Mein!
  void openFullScreenPlayer() {
    if (_currentIndex == -1 || _filteredPlaylist.isEmpty) return;
    
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          
          // Sheet ko update rakhne ke liye listeners
          _player.onPositionChanged.listen((p) { if(mounted) setModalState((){}); });
          _player.onPlayerStateChanged.listen((s) { if(mounted) setModalState((){}); });

          final currentSongPath = _filteredPlaylist[_currentIndex].path;
          final songName = getFileName(currentSongPath);

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              children: [
                // 🎵 Nayi Gol (Circular) Album Art
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: AlbumArtService.buildAlbumArt(
                      filePath: currentSongPath,
                      songName: songName,
                      size: 260,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Song Title & Subtitle
                Text(
                  songName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                const Text("Local Audio", style: TextStyle(color: Colors.grey, fontSize: 16)),
                const Spacer(),

                // Seek Bar Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    activeColor: Colors.deepPurple,
                    inactiveColor: Colors.deepPurple.shade100,
                    min: 0,
                    max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1,
                    value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1),
                    onChanged: (val) async {
                      await _player.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatTime(_position), style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(formatTime(_duration), style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const Spacer(),

                // Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.skip_previous, color: Colors.deepPurple),
                      onPressed: () { playPrevious(); setModalState((){}); },
                    ),
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.deepPurple.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)
                        ]
                      ),
                      child: IconButton(
                        iconSize: 40,
                        color: Colors.white,
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () async {
                          if (isPlaying) await _player.pause(); else await _player.resume();
                          setModalState((){});
                        },
                      ),
                    ),
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.skip_next, color: Colors.deepPurple),
                      onPressed: () { playNext(); setModalState((){}); },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // Scaffold aur Main Screen Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_currentView, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              color: Colors.deepPurple,
              child: const Column(
                children: [
                  Icon(Icons.library_music, size: 70, color: Colors.white),
                  SizedBox(height: 10),
                  Text("Bhai Bhai Music", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(leading: const Icon(Icons.music_note), title: const Text('All Songs'), onTap: () { setView('Songs'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.favorite), title: const Text('Favorites'), onTap: () { setView('Favorites'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.history), title: const Text('Recent'), onTap: () { setView('Recent'); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.folder_open), title: const Text('Manage Folders'), onTap: () { Navigator.pop(context); openFolderManager(); }),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: filterSearchResults,
              decoration: InputDecoration(
                hintText: 'Search your favorite songs...',
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _filteredPlaylist.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text('No songs found in $_currentView', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80), // Space for mini player
                    itemCount: _filteredPlaylist.length,
                    itemBuilder: (context, index) {
                      final song = _filteredPlaylist[index];
                      final songName = getFileName(song.path);
                      final isCurrentSong = index == _currentIndex;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrentSong ? Colors.deepPurple.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                          ]
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          // List item me Album Art lag gaya
                          leading: AlbumArtService.buildAlbumArt(
                            filePath: song.path,
                            songName: songName,
                            size: 50,
                          ),
                          title: Text(
                            songName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.w500,
                              color: isCurrentSong ? Colors.deepPurple : Colors.black87,
                            ),
                          ),
                          subtitle: const Text("Local Audio", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          trailing: IconButton(
                            icon: Icon(
                              _favorites.contains(song.path) ? Icons.favorite : Icons.favorite_border,
                              color: _favorites.contains(song.path) ? Colors.deepPurpleAccent : Colors.grey,
                            ),
                            onPressed: () => toggleFavorite(song.path),
                          ),
                          onTap: () {
                            setState(() => _currentIndex = index);
                            playSong(song.path);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // Mini Player jo list ke neeche rahega
      bottomSheet: _currentIndex >= 0 && _filteredPlaylist.isNotEmpty
          ? GestureDetector(
              onTap: openFullScreenPlayer,
              child: Container(
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade900,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    // Mini Player me bhi Album Art
                    AlbumArtService.buildAlbumArt(
                      filePath: _filteredPlaylist[_currentIndex].path,
                      songName: getFileName(_filteredPlaylist[_currentIndex].path),
                      size: 45,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getFileName(_filteredPlaylist[_currentIndex].path),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text("Tap to open player", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 40),
                      onPressed: () async {
                        if (isPlaying) await _player.pause(); else await _player.resume();
                      },
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

// 📂 Folder Manager Screen
class FolderManagerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> folders;
  final VoidCallback onFoldersUpdated;

  const FolderManagerScreen({Key? key, required this.folders, required this.onFoldersUpdated}) : super(key: key);

  @override
  State<FolderManagerScreen> createState() => _FolderManagerScreenState();
}

class _FolderManagerScreenState extends State<FolderManagerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Music Folders'), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: widget.folders.isEmpty
          ? const Center(child: Text("No folders added. Tap + to add."))
          : ListView.builder(
              itemCount: widget.folders.length,
              itemBuilder: (context, index) {
                final folder = widget.folders[index];
                return CheckboxListTile(
                  activeColor: Colors.deepPurple,
                  title: Text(folder['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(folder['path']),
                  value: folder['isChecked'],
                  onChanged: (val) {
                    setState(() => folder['isChecked'] = val);
                    widget.onFoldersUpdated();
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.create_new_folder),
        label: const Text("Add Folder"),
        onPressed: () async {
          String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
          if (selectedDirectory != null) {
            bool exists = widget.folders.any((f) => f['path'] == selectedDirectory);
            if (!exists) {
              setState(() {
                widget.folders.add({
                  'name': selectedDirectory.split('/').last,
                  'path': selectedDirectory,
                  'isChecked': true,
                });
              });
              widget.onFoldersUpdated();
            }
          }
        },
      ),
    );
  }
}
