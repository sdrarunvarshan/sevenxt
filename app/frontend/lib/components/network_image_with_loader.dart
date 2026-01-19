import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import 'skleton/skelton.dart';

class NetworkImageWithLoader extends StatelessWidget {
  final BoxFit fit;
  final String imageUrl;
  final double radius;
  final double? width;
  final double? height;

  const NetworkImageWithLoader({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = defaultPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Skeleton(), // Must match the ProductCard's AspectRatio
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error, color: Colors.red),
        ),
      ),
    );
  }
}