import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../skelton.dart';
import 'package:flutter/material.dart';

/// Order Status Card Skeleton'
class OrderStatusCardSkelton extends StatelessWidget {
  const OrderStatusCardSkelton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Skeleton(height: 14, width: 140),
                    const SizedBox(height: 4),
                    const Skeleton(height: 12, width: 100),
                  ],
                ),
                const Skeleton(height: 24, width: 80),
              ],
            ),
            const SizedBox(height: defaultPadding),

            /// Products skeleton
            const Skeleton(height: 12, width: 60),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Skeleton(height: 52, width: 52, layer: 1),
                ),
              ),
            ),

            const SizedBox(height: defaultPadding),

            /// Price + Button skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Skeleton(height: 12, width: 60),
                    const SizedBox(height: 4),
                    const Skeleton(height: 14, width: 80),
                  ],
                ),
                const Skeleton(height: 32, width: 100),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
