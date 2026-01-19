import 'package:flutter/material.dart';
import '../../constants.dart';
import '../network_image_with_loader.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.image,
    required this.brandName,
    required this.title,
    required this.price,
    this.priceAfetDiscount,
    this.dicountpercent,
    required this.rating,
    required this.reviews,
    required this.press,
  });

  final String image, brandName, title;
  final double price;
  final double? priceAfetDiscount;
  final int? dicountpercent;
  final double rating;
  final int reviews;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(defaultBorderRadious),
      onTap: press,
      child: Container(
        width: 150,
        height: 260, // ✅ realistic height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: blackColor20.withValues(),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// IMAGE (takes remaining space)
            Expanded(
              child: NetworkImageWithLoader(
                imageUrl: image,
                radius: 0,
              ),
            ),

            /// CONTENT (fixed height)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (brandName.isNotEmpty)
                    Text(
                      brandName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),

                  const SizedBox(height: 4),

                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    priceAfetDiscount != null &&
                        priceAfetDiscount! < price
                        ? '₹${priceAfetDiscount!.toStringAsFixed(0)}'
                        : '₹${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  if (priceAfetDiscount != null &&
                      priceAfetDiscount! < price)
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
