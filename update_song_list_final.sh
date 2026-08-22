#!/bin/bash

# Replace song list with real album art version
sed -i '/Widget _songList() {/,/^  }/c\
  Widget _songList() {\
    if (_visibleSongs.isEmpty) {\
      return Center(\
        child: Column(\
          mainAxisAlignment: MainAxisAlignment.center,\
          children: [\
            const Icon(Icons.library_music, size: 64, color: Colors.black12),\
            const SizedBox(height: 12),\
            Text(\
              _view == "Favorites" ? "No favorites yet" : _view == "Recent" ? "No recent songs" : "No songs found",\
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),\
            ),\
            const SizedBox(height: 18),\
            if (_view == "Songs")\
              FilledButton.icon(\
                onPressed: _addFolder,\
                icon: const Icon(Icons.folder_open),\
                label: const Text("Add Music Folder"),\
              ),\
          ],\
        ),\
      );\
    }\
    return ListView.builder(\
      itemCount: _visibleSongs.length,\
      itemBuilder: (context, index) {\
        final song = _visibleSongs[index];\
        final current = index == _currentIndex && _playing;\
        final songName = fileName(song.path);\
        return Container(\
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),\
          decoration: BoxDecoration(\
            color: current ? Colors.deepPurple.shade50 : Colors.white,\
            borderRadius: BorderRadius.circular(12),\
            boxShadow: [\
              BoxShadow(\
                color: Colors.grey.withOpacity(0.1),\
                blurRadius: 4,\
                offset: const Offset(0, 2),\
              ),\
            ],\
          ),\
          child: ListTile(\
            leading: AlbumArtService.buildAlbumArt(\
              filePath: song.path,\
              songName: songName,\
              size: 50,\
            ),\
            title: Text(\
              songName,\
              maxLines: 1,\
              overflow: TextOverflow.ellipsis,\
              style: TextStyle(\
                fontWeight: current ? FontWeight.bold : FontWeight.w500,\
                color: current ? Colors.deepPurple : Colors.black87,\
              ),\
            ),\
            subtitle: const Text("Local Audio", style: TextStyle(fontSize: 12, color: Colors.grey)),\
            trailing: Row(\
              mainAxisSize: MainAxisSize.min,\
              children: [\
                IconButton(\
                  onPressed: () => _toggleFavorite(song.path),\
                  icon: Icon(\
                    _favorites.contains(song.path) ? Icons.favorite : Icons.favorite_border,\
                    color: _favorites.contains(song.path) ? Colors.deepPurpleAccent : Colors.grey,\
                    size: 20,\
                  ),\
                ),\
                IconButton(\
                  onPressed: () => _addToPlaylist(song),\
                  icon: const Icon(Icons.playlist_add, color: Colors.grey, size: 20),\
                ),\
              ],\
            ),\
            onTap: () => _play(song),\
          ),\
        );\
      },\
    );\
  }' lib/screens/home_screen.dart

echo "✅ Song list updated with real album art!"
