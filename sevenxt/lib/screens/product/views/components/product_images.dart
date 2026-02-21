import 'package:flutter/material.dart';

import '/components/network_image_with_loader.dart';
import '../../../../constants.dart';

class ProductImages extends StatefulWidget {
  const ProductImages({
    super.key,
    required this.images,
  });

  final List<String> images;

  @override
  State<ProductImages> createState() => _ProductImagesState();
}

class _ProductImagesState extends State<ProductImages> {
  late PageController _controller;

  @override
  void initState() {
    _controller = PageController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 🔒 MAX SIZE CAP - Increased for larger products like TVs
        final double size = constraints.maxWidth > 700
            ? 700
            : constraints.maxWidth; // Increased max size

        return Center(
          child: SizedBox(
            width: size * 1.25,
            height: size * 0.8, // Slightly wider aspect ratio for electronics
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: AspectRatio(
                aspectRatio: 1.50, // Wider aspect ratio (5:4)
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(defaultPadding),
                      child: NetworkImageWithLoader(
                        imageUrl: widget.images[index],
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
