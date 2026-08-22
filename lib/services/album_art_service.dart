import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

class AlbumArtService {
  static final FlutterAudioQuery _audioQuery = FlutterAudioQuery();
  static final Map<String, String> _cache = {};
  static final Map<String, Color> _colorCache = {};

  static Future<String?> getAlbumArt(String filePath) async {
    try {
      // Check cache first
      if (_cache.containsKey(filePath)) {
        return _cache[filePath];
      }

      // Try to get album art from file
      final songs = await _audioQuery.getSongs();
      final song = songs.firstWhere(
        (s) => s.filePath == filePath,
        orElse: () => SongInfo(
          id: -1,
          title: '',
          artist: '',
          album: '',
          genre: '',
          duration: 0,
          trackNumber: 0,
          albumArt: null,
          year: 0,
          filePath: '',
          albumId: -1,
          artistId: -1,
        ),
      );

      if (song.albumArt != null) {
        _cache[filePath] = song.albumArt!;
        return song.albumArt!;
      }

      return null;
    } catch (e) {
      print("Error getting album art: $e");
      return null;
    }
  }

  static Color getColorFromName(String name) {
    if (_colorCache.containsKey(name)) {
      return _colorCache[name]!;
    }

    int hash = name.hashCode.abs();
    int hue = hash % 360;
    Color color = HSLColor.fromAHSL(1.0, hue.toDouble(), 0.7, 0.5).toColor();
    _colorCache[name] = color;
    return color;
  }

  static Widget buildAlbumArt({
    required String filePath,
    required String songName,
    double size = 50,
    BorderRadius? borderRadius,
  }) {
    return FutureBuilder<String?>(
      future: getAlbumArt(filePath),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          // Real album art found
          return ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(10),
            child: Image.file(
              File(snapshot.data!),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildDefaultArt(songName, size),
            ),
          );
        } else {
          // Fallback to default art
          return _buildDefaultArt(songName, size);
        }
      },
    );
  }

  static Widget _buildDefaultArt(String songName, double size) {
    final color = getColorFromName(songName);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          songName.isNotEmpty ? songName[0].toUpperCase() : '🎵',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
