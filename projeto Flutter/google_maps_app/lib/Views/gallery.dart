import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GalleryPage extends StatelessWidget {
  final Map<LatLng, String> images;

  const GalleryPage({Key? key, required this.images}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        children: images.entries.map((entry) {
          return GestureDetector(
            onTap: () {
              _showPhotoFullScreen(context, entry.value);
            },
            child: Card(
              child: Image.file(File(entry.value)),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showPhotoFullScreen(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Image.file(File(imagePath)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}