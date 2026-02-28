import 'package:flutter/material.dart';

import '../../constants.dart';
import '../network_image_with_loader.dart';

class SecondaryProductCard extends StatelessWidget {
  const SecondaryProductCard({
    super.key,
    required this.image,
    required this.brandName,
    required this.title,
    required this.price,
    this.priceAfetDiscount,
    this.dicountpercent,
    this.rating,
    this.press,
    this.style,
  });

  final String image, brandName, title;
  final double price;
  final double? priceAfetDiscount;
  final int? dicountpercent;
  final double? rating;
  final VoidCallback? press;

  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      constraints: const BoxConstraints(minHeight: 114),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        border: Border.all(color: blackColor10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: press,
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// IMAGE
              SizedBox(
                width: 80,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    children: [
                      NetworkImageWithLoader(
                        imageUrl: image,
                        radius: defaultBorderRadious,
                      ),
                      if (dicountpercent != null && dicountpercent! > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: errorColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "$dicountpercent% OFF",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              /// CONTENT
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        brandName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(fontSize: 10, color: blackColor40),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                      ),
                      const SizedBox(height: 2),
                      if (rating != null)
                        Row(
                          children: [
                            Icon(Icons.star, size: 10, color: warningColor),
                            const SizedBox(width: 2),
                            Text(
                              rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                      /// PRICE
                      const SizedBox(height: 2),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (priceAfetDiscount != null &&
                              priceAfetDiscount! < price)
                            Text(
                              "₹${price.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 9,
                                color: blackColor40,
                                decoration: TextDecoration.lineThrough,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          Text(
                            "₹${(priceAfetDiscount ?? price).toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
