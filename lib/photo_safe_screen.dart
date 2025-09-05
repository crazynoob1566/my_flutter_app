import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // Удаляем файл с диска
    if (await _photos[index].exists()) {
      await _photos[index].delete();
    }

    // Удаляем путь из списка
    paths.removeAt(index);
    await prefs.setStringList('photos', paths);

    setState(() {
      _photos.removeAt(index);
    });
  }

  void _viewPhoto(File photo, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            actions: [
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  Navigator.pop(context);
                  _deletePhoto(index);
                },
              ),
            ],
          ),
          body: Center(child: InteractiveViewer(child: Image.file(photo))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Фото‑сейф')),
      body: GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _viewPhoto(_photos[index], index),
            child: Image.file(_photos[index], fit: BoxFit.cover),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPhoto,
        child: Icon(Icons.add),
      ),
    );
  }
}
