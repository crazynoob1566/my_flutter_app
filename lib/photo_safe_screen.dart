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
      appBar: AppBar(title: const Text('Фото‑сейф')),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openGallery(index),
            child: Hero(
              tag: 'photo_$index',
              child: Image.file(_photos[index], fit: BoxFit.cover),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPhoto,
        child: const Icon(Icons.add),
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

  late List<PhotoViewController> _controllers;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _controllers = List.generate(
      widget.photos.length,
      (_) => PhotoViewController(),
    );
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
      backgroundColor: Colors.black.withOpacity(opacity),
      body: Stack(
        children: [
          Transform.scale(
            scale: scale,
            child: PhotoViewGallery.builder(
              itemCount: widget.photos.length,
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(widget.photos[index]),
                  controller: _controllers[index],
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  heroAttributes: PhotoViewHeroAttributes(tag: 'photo_$index'),
                  onTapUp: (context, details, value) {
                    final controller = _controllers[index];
                    final currentScale = controller.scale ?? 1.0;
                    final newScale = currentScale == 1.0 ? 2.0 : 1.0;

                    controller.scale = newScale;

                    if (newScale > 1.0) {
                      controller.position = Offset(
                        -(details.localPosition.dx -
                                MediaQuery.of(context).size.width / 2) *
                            newScale,
                        -(details.localPosition.dy -
                                MediaQuery.of(context).size.height / 2) *
                            newScale,
                      );
                    } else {
                      controller.position = Offset.zero;
                    }
                  },
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
                backgroundColor: Colors.black54.withOpacity(opacity),
                title: Text("${currentIndex + 1} / ${widget.photos.length}"),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      Navigator.pop(context, currentIndex);
                    },
                  ),
                ],
              ),
            ),
          GestureDetector(
            onTap: () => setState(() => showUI = !showUI),
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
          ),
        ],
      ),
    );
  }
}
