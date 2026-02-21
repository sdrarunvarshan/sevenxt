import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../constants.dart';
import 'package:sevenxt/models/product_model.dart';
import 'product_availability_tag.dart';

class ProductInfo extends StatelessWidget {
  const ProductInfo({
    super.key,
    required this.product,
  });

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(defaultPadding),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Brand
            Text(
              product.brandName.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: defaultPadding / 2),

            /// Title
            Text(
              product.title,
              maxLines: 2,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: defaultPadding),

            /// Availability + Rating
            Row(
              children: [
                ProductAvailabilityTag(product: product),
                const Spacer(),
                SvgPicture.asset("assets/icons/Star_filled.svg"),
                const SizedBox(width: defaultPadding / 4),
                Text(
                  product.rating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(width: 4),
                Text("(${product.reviews} Reviews)"),
              ],
            ),

            const SizedBox(height: defaultPadding),

            /// Info title
            Text(
              "Product info",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: defaultPadding / 2),

            /// Product Info / Description
            Text(
              _buildProductInfo(product),
              style: const TextStyle(height: 1.4),
            ),

            const SizedBox(height: defaultPadding / 2),
          ],
        ),
      ),
    );
  }

  /// ========================= INFO HANDLER =========================
  String _buildProductInfo(ProductModel product) {

    final buffer = StringBuffer();
    if (product.hsnCode != null && product.hsnCode!.isNotEmpty) {
      buffer.writeln("HSN Code: ${product.hsnCode}");
      buffer.writeln(); // spacing
    }

    // Add dimensions first


    // 1️⃣ If info is null → fallback to description
    final info = product.info;

    if (info == null) {
      if (product.description?.isNotEmpty == true) {
        buffer.writeln(product.description!);
      } else {
        buffer.writeln("No product information available.");
      }
    } else if (info is String && info.trim().isNotEmpty) {
      buffer.writeln(info);
    } else if (info is Map) {
      for (var entry in info.entries) {
        buffer.writeln("${_capitalize(entry.key)}: ${entry.value}");
      }
    } else if (info is List) {
      for (var item in info) {
        buffer.writeln("• $item");
      }
    }
    buffer.writeln("Weight: ${product.weightKg} kg");
    buffer.writeln("Length: ${product.lengthCm} cm");
    buffer.writeln("Breadth: ${product.breadthCm} cm");
    buffer.writeln("Height: ${product.heightCm} cm");

    return buffer.toString();
  }
  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
