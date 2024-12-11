// lib/screens/full_screen_image_viewer.dart

import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  final String tag;

  const FullScreenImageViewer({
    Key? key,
    required this.imagePath,
    required this.tag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color for better visibility
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Hero(
          tag: tag, // Unique tag for Hero animation
          child: InteractiveViewer(
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
