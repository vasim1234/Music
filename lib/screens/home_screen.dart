import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
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
      setState(() => isPlaying = state == PlayerState.playing);
      _updateLockScreenControls();
    });
    _player.onPlayerComplete.listen((event) => playNext());
    
    _loadData();
    _checkPermission();
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

  void openFullScreenPlayer() {
    if (_currentIndex == -1 || _filteredPlaylist.isEmpty) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
