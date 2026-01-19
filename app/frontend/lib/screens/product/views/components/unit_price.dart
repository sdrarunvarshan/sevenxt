import 'package:flutter/material.dart';
import '../../../../constants.dart';

class UnitPrice extends StatelessWidget {
  const UnitPrice({
    super.key,
    required this.price,
    this.priceAfterDiscount,
    this.discountPercent,

  });

  final double price; // original price
  final double? priceAfterDiscount; // discounted price
  final int? discountPercent;

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        priceAfterDiscount != null && priceAfterDiscount! < price;

    int displayPrice(double value) => value.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Unit price",
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: defaultPadding / 1),
        Row(children: [
          // Strike-through original price if discount exists
          if (hasDiscount)
            Text(
              "₹${displayPrice(price)}",
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                    decoration: TextDecoration.lineThrough,
                  ),
            ),

          if (hasDiscount) const SizedBox(width: 8),

          // Current price
          Text(
            "₹${displayPrice(hasDiscount ? priceAfterDiscount! : price)}",
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: hasDiscount ? Colors.lightBlue : null,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (hasDiscount &&
              discountPercent != null &&
              discountPercent! > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "-$discountPercent%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ]),
      ],
    );
  }
}
