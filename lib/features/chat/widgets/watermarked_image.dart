import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class WatermarkedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const WatermarkedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Main Image
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImage(),
        ),


        // Watermark Overlay
        Positioned(
          bottom: 8,
          right: 8,
          child: Opacity(
            opacity: 0.8,
            child: Image.asset(
              'assets/images/watermark.png',
              height: 20, // Small and subtle
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildImage() {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: _buildError,
        );
      } catch (e) {
        return _buildError(null, e, null);
      }
    }
    
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
             width: 24, 
             height: 24, 
             child: CircularProgressIndicator(
               value: loadingProgress.expectedTotalBytes != null
                   ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                   : null,
               strokeWidth: 2,
             ),
          ),
        );
      },
      errorBuilder: _buildError,
    );
  }

  Widget _buildError(BuildContext? context, Object error, StackTrace? stackTrace) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 200,
      color: Colors.white10,
      child: const Icon(Icons.broken_image, color: Colors.white24),
    );
  }
}
