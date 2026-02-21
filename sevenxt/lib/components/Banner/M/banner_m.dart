import 'package:flutter/material.dart';

import '../../network_image_with_loader.dart';

class BannerM extends StatelessWidget {
  const BannerM({
    super.key,
    required this.image,
    required this.press,
    required this.children,
  });

  final String image;
  final VoidCallback press;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Stack(
        children: [
          NetworkImageWithLoader(
            imageUrl: image,
            width: double.infinity,
            height: double.infinity,
            radius: 0,
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black45),
          ...children,
        ],
      ),
    );
  }
}
