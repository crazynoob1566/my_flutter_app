import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PhotoSafeScreen extends StatefulWidget {
  const PhotoSafeScreen({super.key});

  @override
  State<PhotoSafeScreen> createState() => _PhotoSafeScreenState();
}

class _PhotoSafeScreenState extends State<PhotoSafeScreen> {
  List<File> _photos = [];
  bool _selectionMode = false;
  Set<int> _selectedIndexes = {};

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList('photos') ?? [];
    setState(() {
      _photos = paths.map((path) => File(path)).toList();
    });
  }

  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final newPath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newImage = await File(pickedFile.path).copy(newPath);

      final prefs = await SharedPreferences.getInstance();
      final paths = prefs.getStringList('photos') ?? [];
      paths.add(newImage.path);
      await prefs.setStringList('photos', paths);

      setState(() {
        _photos.add(newImage);
      });
    }
  }

  Future<void> _deletePhoto(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList('photos') ?? [];

    if (await _photos[index].exists()) {
      await _photos[index].delete();
    }

    paths.removeAt(index);
    await prefs.setStringList('photos', paths);

    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _deleteSelected() async {
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList('photos') ?? [];

    final toDelete = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
    for (var index in toDelete) {
      if (await _photos[index].exists()) {
        await _photos[index].delete();
      }
      paths.removeAt(index);
      _photos.removeAt(index);
    }

    await prefs.setStringList('photos', paths);
    setState(() {
      _selectionMode = false;
      _selectedIndexes.clear();
    });
  }

  void _toggleSelectionMode([bool? enable]) {
    setState(() {
      _selectionMode = enable ?? !_selectionMode;
      _selectedIndexes.clear();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIndexes.length == _photos.length) {
        _selectedIndexes.clear();
      } else {
        _selectedIndexes = Set.from(List.generate(_photos.length, (i) => i));
      }
    });
  }

  void _openGallery(int initialIndex) async {
    final deletedIndex = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GalleryScreen(photos: _photos, initialIndex: initialIndex),
      ),
    );
    if (deletedIndex != null) {
      _deletePhoto(deletedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        elevation: 0,
        title: Text(
          _selectionMode ? "${_selectedIndexes.length} выбрано" : "Фото‑сейф",
          style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 20),
        ),
        actions: _selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _toggleSelectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _selectedIndexes.isEmpty ? null : _deleteSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _toggleSelectionMode(false),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: () => _toggleSelectionMode(true),
                ),
              ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final selected = _selectedIndexes.contains(index);
          return GestureDetector(
            onLongPress: () => _toggleSelectionMode(true),
            onTap: () {
              if (_selectionMode) {
                setState(() {
                  if (selected) {
                    _selectedIndexes.remove(index);
                  } else {
                    _selectedIndexes.add(index);
                  }
                });
              } else {
                _openGallery(index);
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_photos[index], fit: BoxFit.cover),
                ),
                if (_selectionMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected ? Colors.blue : Colors.white70,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: !_selectionMode
          ? FloatingActionButton(
              backgroundColor: Colors.white.withValues(alpha: 0.85),
              child: const Icon(Icons.add, color: Colors.black),
              onPressed: _addPhoto,
            )
          : null,
    );
  }
}

class GalleryScreen extends StatefulWidget {
  final List<File> photos;
  final int initialIndex;

  const GalleryScreen({super.key, required this.photos, this.initialIndex = 0});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late int currentIndex;
  bool showUI = true;
  late PageController _pageController;
  double dragOffset = 0;
  double opacity = 1.0;
  double scale = 1.0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      dragOffset += details.delta.dy;
      opacity = (1 - (dragOffset.abs() / 300)).clamp(0.0, 1.0);
      scale = (1 - (dragOffset.abs() / 1000)).clamp(0.8, 1.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (dragOffset.abs() > 150) {
      Navigator.pop(context);
    } else {
      setState(() {
        dragOffset = 0;
        opacity = 1.0;
        scale = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: opacity),
      body: GestureDetector(
        onTap: () => setState(() => showUI = !showUI),
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          children: [
            Transform.scale(
              scale: scale,
              child: PhotoViewGallery.builder(
                itemCount: widget.photos.length,
                pageController: _pageController,
                onPageChanged: (index) => setState(() => currentIndex = index),
                builder: (context, index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: FileImage(widget.photos[index]),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 3,
                    heroAttributes: PhotoViewHeroAttributes(
                      tag: 'photo_$index',
                    ),
                  );
                },
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
            ),
            if (showUI)
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: AppBar(
                  backgroundColor: Colors.black54.withValues(alpha: opacity),
                  elevation: 0,
                  title: Text(
                    "${currentIndex + 1} / ${widget.photos.length}",
                    style: const TextStyle(fontWeight: FontWeight.w300),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        Navigator.pop(context, currentIndex);
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
