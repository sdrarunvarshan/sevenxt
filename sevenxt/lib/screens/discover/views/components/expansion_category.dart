import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sevenxt/constants.dart';

class ExpansionCategory extends StatelessWidget {
  const ExpansionCategory({
    super.key,
    required this.title,
    required this.svgSrc,
    this.image,
    this.onCategoryTap,
  });

  final String title, svgSrc;
  final String? image;
  final VoidCallback? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding / 2,
      ),
      child: Center(
        // Added Center widget
        child: ConstrainedBox(
          // Added ConstrainedBox to limit width
          constraints: const BoxConstraints(
              maxWidth: 700), // Max width for larger screens
          child: GestureDetector(
            onTap: onCategoryTap,
            child: AspectRatio(
              aspectRatio: 2.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(defaultBorderRadious),
                child: Stack(
                  children: [
                    // Background Image
                    if (image != null && image!.isNotEmpty)
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: image!,
                          fit: BoxFit.cover,
                          httpHeaders: const {
                            'User-Agent': 'Mozilla/5.0',
                          },
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                    // Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.black.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Content (Icon + Title) — ONLY ONCE
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              svgSrc,
                              height: 24,
                              width: 24,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: defaultPadding / 2),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
