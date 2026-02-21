// lib/screens/order/components/order_status_card.dart
import 'package:flutter/material.dart';

import '../../../../../constants.dart';
import '../../../../../models/order_model.dart';
import '../order_process.dart';

class OrderStatusCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final bool showDetailsButton;

  const OrderStatusCard({
    super.key,
    required this.order,
    this.onTap,
    this.showDetailsButton = true,
  });

  String get _safeOrderId {
    if (order.id.length <= 6) return order.id;
    return order.id.substring(order.id.length - 6);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        final imageSize = isWide ? 64.0 : 52.0;

        return Card(
          margin: const EdgeInsets.only(bottom: defaultPadding),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Order ID + Date + Status Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #$_safeOrderId',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              order.formattedDate,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      OrderStatusBadge(status: order.orderStatus),
                    ],
                  ),

                  const SizedBox(height: defaultPadding),

                  /// Items
                  _buildProductSummary(context, imageSize),

                  const SizedBox(height: defaultPadding / 2),

                  /// Price + Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${order.totalItems} items'),
                          Text(
                            '₹${order.totalPrice.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor,
                                ),
                          ),
                        ],
                      ),
                      if (showDetailsButton && onTap != null)
                        TextButton(
                          onPressed: onTap,
                          style: TextButton.styleFrom(
                            foregroundColor: kPrimaryColor,
                          ),
                          child: const Text('View Details'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductSummary(BuildContext context, double imageSize) {
    final displayProducts = order.products.length > 3
        ? order.products.take(3).toList()
        : order.products;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...displayProducts.map(
              (product) => Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                  image: product.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imageUrl.isEmpty
                    ? Icon(Icons.shopping_bag_outlined,
                        color: Colors.grey.shade400)
                    : null,
              ),
            ),
            if (order.products.length > 3)
              Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                ),
                child: Center(
                  child: Text(
                    '+${order.products.length - 3}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
