import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _search = TextEditingController();
  final List<Map<String, dynamic>> _folders = [];
  final List<File> _songs = [];
  List<File> _visibleSongs = [];
  List<String> _favorites = [];
  List<String> _recent = [];
  List<Map<String, dynamic>> _playlists = [];
  String _view = 'Songs';
  String? _playlistDetail;
  int _currentIndex = -1;
  bool _playing = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _stateSub, _durationSub, _positionSub, _completeSub;
  bool _isScanning = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s == PlayerState.playing);
    });
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _completeSub = _player.onPlayerComplete.listen((_) => _next());
    _requestPermissionsAndLoad();
  }

  Future<void> _requestPermissionsAndLoad() async {
    if (Platform.isAndroid) {
      // Android 13+ requires READ_MEDIA_AUDIO
      if (await Permission.storage.status.isGranted ||
          await Permission.audio.status.isGranted ||
          await Permission.photos.status.isGranted) {
        _load();
      } else {
        // Request all permissions
        await [
          Permission.storage,
          Permission.audio,
          Permission.photos,
          Permission.manageExternalStorage,
        ].request();
        _load();
      }
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final folders = p.getStringList('folders') ?? [];
    _favorites = p.getStringList('favorites') ?? [];
    _recent = p.getStringList('recent') ?? [];
    final playlistStrings = p.getStringList('playlists') ?? [];
    _playlists = [];
    for (final item in playlistStrings) {
      final parts = item.split('|||');
      if (parts.isEmpty) continue;
      _playlists.add({
        'name': parts.first,
        'songs': parts.length > 1 ? parts[1].split('|').where((e) => e.isNotEmpty).toList() : <String>[],
      });
    }
    _folders..clear()..addAll(folders.map((path) => ({
      'name': path.split(Platform.pathSeparator).last,
      'path': path,
      'enabled': true,
    })));
    await _scan();
    if (mounted) setState(() {});
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('folders', _folders.map((e) => e['path'] as String).toList());
    await p.setStringList('favorites', _favorites);
    await p.setStringList('recent', _recent);
    await p.setStringList('playlists', _playlists.map((e) => '${e['name']}|||${(e['songs'] as List<String>).join('|')}').toList());
  }

  // ✅ FIX: Scoped Storage - Use FilePicker with proper path handling
  Future<List<File>> _getAudioFilesFromUri(String path) async {
    final List<File> audioFiles = [];
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File && _isAudio(entity.path)) {
            audioFiles.add(entity);
          }
        }
      }
    } catch (e) {
      print("Error reading directory: $e");
    }
    return audioFiles;
  }

  Future<List<File>> _scanDirectorySafe(Directory dir) async {
    final List<File> foundFiles = [];
    try {
      final List<FileSystemEntity> entities = await dir.list().toList();
      for (final entity in entities) {
        try {
          if (entity is File) {
            final String path = entity.path.toLowerCase();
            if (_isAudio(path)) {
              foundFiles.add(entity);
            }
          } else if (entity is Directory) {
            final String dirName = entity.path.split(Platform.pathSeparator).last;
            if (dirName.startsWith('.')) continue;
            try {
              final subFiles = await _scanDirectorySafe(entity);
              foundFiles.addAll(subFiles);
            } catch (e) { continue; }
          }
        } catch (e) { continue; }
      }
    } catch (e) { print("Error scanning: $e"); }
    return foundFiles;
  }

  Future<void> _scan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _songs.clear();
      _visibleSongs.clear();
    });
    final result = <File>[];
    for (final folder in _folders.where((e) => e['enabled'] == true)) {
      final dir = Directory(folder['path'] as String);
      if (!await dir.exists()) continue;
      try {
        final files = await _scanDirectorySafe(dir);
        result.addAll(files);
        print("✅ Found ${files.length} songs in ${folder['path']}");
      } catch (e) {
        print("⚠️ Error scanning ${folder['path']}: $e");
        continue;
      }
    }
    result.sort((a, b) => fileName(a.path).toLowerCase().compareTo(fileName(b.path).toLowerCase()));
    if (!mounted) return;
    setState(() {
      _songs..clear()..addAll(result);
      _isScanning = false;
    });
    _filter(_search.text);
    print("🎵 Total songs: ${_songs.length}");
  }

  bool _isAudio(String path) {
    final p = path.toLowerCase();
    const exts = ['.mp3', '.m4a', '.aac', '.wav', '.ogg', '.flac', '.wma', '.opus'];
    return exts.any(p.endsWith);
  }

  String fileName(String path) {
    final name = path.split(Platform.pathSeparator).last;
    return name.replaceFirst(RegExp(r'\.[^.]+$'), '').replaceAll(RegExp(r'\([^)]*\)'), '').replaceAll(RegExp(r'\[[^]]*\]'), '').replaceAll('_', ' ').replaceAll('-', ' ').trim();
  }

  List<File> _baseList() {
    switch (_view) {
      case 'Favorites': return _songs.where((f) => _favorites.contains(f.path)).toList();
      case 'Recent': return _recent.map(File.new).where((f) => f.existsSync()).toList();
      case 'PlaylistDetail':
        final p = _playlists.firstWhere((e) => e['name'] == _playlistDetail, orElse: () => {'name': '', 'songs': <String>[]});
        final paths = p['songs'] as List<String>;
        return _songs.where((f) => paths.contains(f.path)).toList();
      default: return List<File>.from(_songs);
    }
  }

  void _filter(String query) {
    final base = _baseList();
    final q = query.trim().toLowerCase();
    setState(() {
      _visibleSongs = q.isEmpty ? base : base.where((f) => fileName(f.path).toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _play(File file) async {
    final index = _visibleSongs.indexWhere((f) => f.path == file.path);
    if (index < 0) return;
    setState(() => _currentIndex = index);
    await _player.play(DeviceFileSource(file.path));
    _recent.remove(file.path);
    _recent.insert(0, file.path);
    if (_recent.length > 50) _recent.removeLast();
    await _save();
  }

  Future<void> _next() async {
    if (_visibleSongs.isEmpty) return;
    final next = _currentIndex + 1;
    if (next >= _visibleSongs.length) return;
    await _play(_visibleSongs[next]);
  }

  Future<void> _previous() async {
    if (_visibleSongs.isEmpty) return;
    final prev = _currentIndex - 1;
    if (prev < 0) return;
    await _play(_visibleSongs[prev]);
  }

  void _setView(String view) {
    setState(() {
      _view = view;
      if (view != 'PlaylistDetail') _playlistDetail = null;
      _search.clear();
    });
    _filter('');
  }

  Future<void> _toggleFavorite(String path) async {
    setState(() {
      if (_favorites.contains(path)) _favorites.remove(path);
      else _favorites.add(path);
    });
    await _save();
    _filter(_search.text);
  }

  // ✅ FIX: Proper folder add with state refresh
  Future<void> _addFolder() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) return;
      final path = result;
      print("📁 Selected folder: $path");
      
      // Check if already exists
      if (_folders.any((f) => f['path'] == path)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Folder already added.')),
          );
        }
        return;
      }
      
      // Add folder
      setState(() {
        _folders.add({
          'name': path.split(Platform.pathSeparator).last,
          'path': path,
          'enabled': true,
        });
      });
      
      await _save();
      
      // ✅ IMPORTANT: Scan and refresh UI
      await _scan();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Added: ${path.split(Platform.pathSeparator).last} (${_songs.length} songs)')),
        );
        setState(() {}); // Force UI refresh
      }
    } catch (e) {
      print("❌ Folder error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    setState(() {
      _playlists.add({'name': name, 'songs': <String>[]});
    });
    await _save();
    _setView('Playlists');
  }

  Future<void> _addToPlaylist(File song) async {
    if (_playlists.isEmpty) {
      await _createPlaylist();
      if (_playlists.isEmpty) return;
    }
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Add to Playlist'),
        children: List.generate(_playlists.length, (i) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, i),
          child: Text(_playlists[i]['name'] as String),
        )),
      ),
    );
    if (selected == null) return;
    final songs = _playlists[selected]['songs'] as List<String>;
    if (!songs.contains(song.path)) songs.add(song.path);
    await _save();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to playlist.')));
  }

  String _time(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _openPlayer() {
    if (_currentIndex < 0 || _currentIndex >= _visibleSongs.length) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) {
          return Container(
            height: MediaQuery.sizeOf(context).height * .94,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                      ),
                      const Text('Now Playing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Container(
                  width: 260,
                  height: 260,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF4C83FF), Color(0xFFD946EF)],
                    ),
                  ),
                  child: const Icon(Icons.music_note, size: 120, color: Colors.white),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Text(
                    fileName(_visibleSongs[_currentIndex].path),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold),
                  ),
                ),
                const Text('Local Audio', style: TextStyle(color: Colors.white54)),
                const Spacer(),
                Slider(
                  value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                  min: 0,
                  max: (_duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1).toDouble(),
                  onChanged: (v) async {
                    await _player.seek(Duration(milliseconds: v.round()));
                    setModal(() {});
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_time(_position), style: const TextStyle(color: Colors.white54)),
                      Text(_time(_duration), style: const TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      iconSize: 30,
                      onPressed: () async {
                        await _toggleFavorite(_visibleSongs[_currentIndex].path);
                        setModal(() {});
                      },
                      icon: Icon(
                        _favorites.contains(_visibleSongs[_currentIndex].path) ? Icons.favorite : Icons.favorite_border,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      iconSize: 48,
                      onPressed: () async {
                        await _previous();
                        setModal(() {});
                      },
                      icon: const Icon(Icons.skip_previous, color: Colors.white),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.purpleAccent,
                      ),
                      child: IconButton(
                        iconSize: 42,
                        onPressed: () async {
                          if (_playing) {
                            await _player.pause();
                          } else {
                            await _player.resume();
                          }
                          setModal(() {});
                        },
                        icon: Icon(_playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
                      ),
                    ),
                    IconButton(
                      iconSize: 48,
                      onPressed: () async {
                        await _next();
                        setModal(() {});
                      },
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                    ),
                    IconButton(
                      iconSize: 28,
                      onPressed: () => _addToPlaylist(_visibleSongs[_currentIndex]),
                      icon: const Icon(Icons.playlist_add, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 45),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _songList() {
    if (_isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('Scanning music files...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    if (_visibleSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_music, size: 64, color: Colors.black12),
            const SizedBox(height: 12),
            Text(
              _view == 'Favorites' ? 'No favorites yet' : _view == 'Recent' ? 'No recent songs' : 'No songs found',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            if (_view == 'Songs')
              Column(
                children: [
                  const Text('Add a music folder to get started.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _addFolder,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Add Music Folder'),
                  ),
                ],
              ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _visibleSongs.length,
      itemBuilder: (context, index) {
        final song = _visibleSongs[index];
        final current = index == _currentIndex && _playing;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: current ? Colors.deepPurple : Colors.grey.shade200,
            child: Icon(Icons.music_note, color: current ? Colors.white : Colors.grey),
          ),
          title: Text(
            fileName(song.path),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: current ? FontWeight.bold : FontWeight.w500,
              color: current ? Colors.deepPurple : Colors.black87,
            ),
          ),
          subtitle: const Text('Local Audio'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _toggleFavorite(song.path),
                icon: Icon(
                  _favorites.contains(song.path) ? Icons.favorite : Icons.favorite_border,
                  color: _favorites.contains(song.path) ? Colors.deepPurpleAccent : Colors.grey,
                ),
              ),
              IconButton(
                onPressed: () => _addToPlaylist(song),
                icon: const Icon(Icons.playlist_add, color: Colors.grey),
              ),
            ],
          ),
          onTap: () => _play(song),
        );
      },
    );
  }

  Widget _playlistsView() {
    if (_playlists.isEmpty) {
      return Center(
        child: FilledButton.icon(
          onPressed: _createPlaylist,
          icon: const Icon(Icons.add),
          label: const Text('Create Playlist'),
        ),
      );
    }
    return ListView.builder(
      itemCount: _playlists.length,
      itemBuilder: (context, i) {
        final p = _playlists[i];
        final songs = p['songs'] as List<String>;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.queue_music)),
            title: Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${songs.length} songs'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                setState(() => _playlists.removeAt(i));
                await _save();
              },
            ),
            onTap: () {
              setState(() {
                _playlistDetail = p['name'] as String;
                _view = 'PlaylistDetail';
              });
              _filter('');
            },
          ),
        );
      },
    );
  }

  Widget _body() {
    if (_view == 'Playlists') return _playlistsView();
    if (_view == 'PlaylistDetail') {
      return Column(
        children: [
          ListTile(
            leading: const BackButton(),
            title: Text(_playlistDetail ?? 'Playlist'),
            onTap: () => _setView('Playlists'),
          ),
          Expanded(child: _songList()),
        ],
      );
    }
    return _songList();
  }

  Widget _tab(String name) {
    final selected = _view == name;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setView(name),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniPlayer() {
    final title = fileName(_visibleSongs[_currentIndex].path);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openPlayer,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE4F1), Color(0xFFE9D5FF)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.black87,
                child: Icon(Icons.music_note, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                onPressed: () => _playing ? _player.pause() : _player.resume(),
                icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              ),
              IconButton(
                onPressed: _next,
                icon: const Icon(Icons.skip_next),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _search,
          onChanged: _filter,
          decoration: const InputDecoration(
            hintText: 'Search songs...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFFD946EF)],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.headphones, color: Colors.white, size: 45),
                    SizedBox(height: 12),
                    Text('Bhai Bhai App', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Local Music Player', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Choose Folders'),
                onTap: () {
                  Navigator.pop(context);
                  _addFolder();
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Scan Music'),
                onTap: () {
                  Navigator.pop(context);
                  _scan();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.lyrics, color: Colors.pink),
                title: const Text('Lyrics'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.equalizer, color: Colors.orange),
                title: const Text('Visualizer'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack, color: Colors.teal),
                title: const Text('Audio Effects'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.radio, color: Colors.blue),
                title: const Text('FM Radio'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.timer, color: Colors.orange),
                title: const Text('Sleep Timer'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.palette, color: Colors.pink),
                title: const Text('Themes'),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                _tab('Songs'),
                _tab('Favorites'),
                _tab('Recent'),
                _tab('Playlists'),
              ],
            ),
          ),
          Expanded(child: _body()),
          if (_currentIndex >= 0 && _visibleSongs.isNotEmpty) _miniPlayer(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.headphones), label: 'My Music'),
          NavigationDestination(icon: Icon(Icons.play_circle_outline), label: 'Watch'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    _search.dispose();
    super.dispose();
  }
}
