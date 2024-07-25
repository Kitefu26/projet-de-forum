import 'package:flutter/material.dart';

class ImageScreen extends StatelessWidget {
  final String imageUrl;

  ImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voir l\'image'),
        backgroundColor: Color(0xFF2f7dc8),
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
