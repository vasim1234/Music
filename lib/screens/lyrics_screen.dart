import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LyricsScreen extends StatefulWidget {
  final String songName;
  final String artist;
  
  const LyricsScreen({
    super.key,
    required this.songName,
    this.artist = 'Unknown Artist',
  });

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  String? _lyrics;
  bool _isLoading = true;
  bool _hasError = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  Future<void> _fetchLyrics() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Try multiple APIs
      String? lyrics = await _fetchFromLyricsOvh();
      
      if (lyrics == null || lyrics.isEmpty) {
        lyrics = await _fetchFromApiLyrics();
      }

      if (mounted) {
        setState(() {
          _lyrics = lyrics;
          _isLoading = false;
          _hasError = lyrics == null || lyrics.isEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<String?> _fetchFromLyricsOvh() async {
    try {
      final artist = Uri.encodeComponent(widget.artist);
      final song = Uri.encodeComponent(widget.songName);
      final url = Uri.parse('https://api.lyrics.ovh/v1/$artist/$song');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['lyrics'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _fetchFromApiLyrics() async {
    try {
      final song = Uri.encodeComponent(widget.songName);
      final url = Uri.parse('https://api.lyrics.ovh/suggest/$song');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = data['data'] as List?;
        if (suggestions != null && suggestions.isNotEmpty) {
          final first = suggestions.first;
          final artist = first['artist']['name'] as String? ?? widget.artist;
          final title = first['title'] as String? ?? widget.songName;
          // Fetch actual lyrics
          return await _fetchFromLyricsOvh();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _showManualLyricsDialog() {
    final controller = TextEditingController(text: _lyrics ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Lyrics'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 15,
            decoration: const InputDecoration(
              hintText: 'Enter lyrics here...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _lyrics = controller.text;
                _hasError = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lyrics saved manually!'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.songName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.artist,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLyrics,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showManualLyricsDialog,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey.shade900, Colors.black]
                : [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 20),
            Text('Fetching lyrics...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_hasError || _lyrics == null || _lyrics!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 20),
              const Text(
                'Lyrics not found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Could not find lyrics for "${widget.songName}"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _showManualLyricsDialog,
                icon: const Icon(Icons.edit),
                label: const Text('Add Manual Lyrics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SelectableText(
              _lyrics!,
              style: TextStyle(
                fontSize: 18,
                height: 1.8,
                color: isDark ? Colors.white70 : Colors.black87,
                fontFamily: 'serif',
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  isDark ? Colors.black : Colors.white,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
