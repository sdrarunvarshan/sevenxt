import 'package:flutter/material.dart';
import 'package:sevenxt/constants.dart';
import 'package:sevenxt/models/product_model.dart';

class ProductAvailabilityTag extends StatelessWidget {
  const ProductAvailabilityTag({
    super.key,
    required this.product,
  });

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final bool available = product.isAvailable;
    final int stock = product.stock;

    return Container(
      padding: const EdgeInsets.all(defaultPadding / 2),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
        borderRadius: const BorderRadius.all(
          Radius.circular(defaultBorderRadious / 2),
        ),
      ),
      child: Text(
        available
            ? "In stock ($stock)"
            : "Out of stock",
        style: Theme.of(context)
            .textTheme
            .labelSmall!
            .copyWith(
          color:blackColor5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
