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
  final GlobalKey<AnimatedGridState> _gridKey = GlobalKey<AnimatedGridState>();
  List<File> _photos = [];

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
        _gridKey.currentState?.insertItem(
          _photos.length - 1,
          duration: const Duration(milliseconds: 300),
        );
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

    final removedPhoto = _photos.removeAt(index);
    _gridKey.currentState?.removeItem(
      index,
      (context, animation) =>
          _buildAnimatedItem(removedPhoto, index, animation),
      duration: const Duration(milliseconds: 300),
    );
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

  Widget _buildAnimatedItem(
    File photo,
    int index,
    Animation<double> animation,
  ) {
    return ScaleTransition(
      scale: animation,
      child: FadeTransition(
        opacity: animation,
        child: GestureDetector(
          onTap: () => _openGallery(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Hero(
              tag: 'photo_$index',
              child: Image.file(photo, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        elevation: 0,
        title: const Text(
          'Фото‑сейф',
          style: TextStyle(fontWeight: FontWeight.w300, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: AnimatedGrid(
        key: _gridKey,
        initialItemCount: _photos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, index, animation) {
          return _buildAnimatedItem(_photos[index], index, animation);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: _addPhoto,
      ),
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
