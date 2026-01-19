import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../skelton.dart';

class SeconderyProductSkelton extends StatelessWidget {
  const SeconderyProductSkelton({
    super.key,
    this.isSmall = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  final bool isSmall;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      height: 114,
      width: 256,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.transparent), // Matching OutlinedButton structure
      ),
      child: Row(
        children: [
          const AspectRatio(
            aspectRatio: 1.15,
            child: Skeleton(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand name
                  const Skeleton(
                    height: 10,
                    width: 60,
                  ),

                  const SizedBox(height: 4),

                  // Title
                  const Skeleton(
                    height: 12,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 2),
                  const Skeleton(
                    height: 12,
                    width: 100,
                  ),

                  const SizedBox(height: 4),

                  // Rating skeleton
                  const Skeleton(
                    height: 10,
                    width: 30,
                  ),

                  const SizedBox(height: 6),


                  // Price
                  const Skeleton(
                    width: 50,
                    height: 12,
                  ),
                ],
              ),

            ),
          )
        ],
      ),
    );
  }
}
