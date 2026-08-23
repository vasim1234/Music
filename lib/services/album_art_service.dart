import 'package:flutter/material.dart';

class AlbumArtService {
  static final Map<String, Color> _colorCache = {};

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
        borderRadius: borderRadius ?? BorderRadius.circular(10),
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
