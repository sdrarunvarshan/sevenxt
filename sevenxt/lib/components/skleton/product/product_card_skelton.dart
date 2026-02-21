import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../skelton.dart';

class ProductCardSkelton extends StatelessWidget {
  const ProductCardSkelton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // 👈 important
        children: [
          /// IMAGE SKELETON
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(defaultBorderRadious),
              ),
              child: Skeleton(),
            ),
          ),

          /// CONTENT SKELETON
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Skeleton(height: 10, width: 80),
                SizedBox(height: 6),

                Skeleton(height: 12),
                SizedBox(height: 4),
                Skeleton(height: 12, width: 120),

                SizedBox(height: 8),

                Skeleton(height: 16, width: 80),
                SizedBox(height: 4),
                Skeleton(height: 10, width: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
