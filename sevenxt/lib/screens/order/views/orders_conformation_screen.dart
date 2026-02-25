// lib/screens/order/views/order_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:sevenxt/constants.dart';
import 'package:sevenxt/models/order_model.dart';
import 'package:sevenxt/route/route_constants.dart';
import 'package:sevenxt/screens/order/views/orders_repository.dart';

import '../../product/views/components/selected_colors.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
        centerTitle: true,
      ),
      // 1. Center and Constrain the Body for Web/Desktop
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Success Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimaryColor.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: defaultPadding * 1.5),

                // Success Message
                Text(
                  'Order Placed Successfully!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: defaultPadding / 2),

                Text(
                  'Your order has been confirmed and will be shipped soon',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: defaultPadding * 2),

                // Order ID
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: defaultPadding,
                    vertical: defaultPadding / 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Order ID: ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        order.id.length > 8
                            ? order.id.substring(order.id.length - 8)
                            : order.id,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                      ),
                      const SizedBox(width: defaultPadding / 2),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          // Implement copy to clipboard logic here
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: defaultPadding * 2),

                // Product List Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ordered Items (${order.products.length})',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: defaultPadding),
                        ...order.products.map((product) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: defaultPadding),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: product.imageUrl.isNotEmpty
                                        ? DecorationImage(
                                            image:
                                                NetworkImage(product.imageUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color: product.imageUrl.isEmpty
                                        ? Colors.grey.shade100
                                        : null,
                                  ),
                                  child: product.imageUrl.isEmpty
                                      ? Center(
                                          child: Icon(
                                            Icons.shopping_bag,
                                            color: Colors.grey.shade400,
                                            size: 30,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: defaultPadding),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: mapColorNameToColor(
                                                  product.colorHex),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Qty: ${product.quantity}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: defaultPadding),

                // Order Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: defaultPadding),
                        _buildDetailRow(
                          context,
                          'Order Date',
                          '${order.formattedDate} at ${order.formattedTime}',
                        ),
                        _buildDetailRow(
                          context,
                          'Payment Method',
                          order.paymentMethod.toUpperCase(),
                        ),
                        _buildDetailRow(
                          context,
                          'Payment Status',
                          order.paymentStatus,
                          isStatus: true,
                        ),
                        _buildDetailRow(
                          context,
                          'Shipping Address',
                          order.customerAddressText,
                          isMultiLine: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: defaultPadding),
// Cancellation Option
                TextButton(
                  onPressed: () => _showCancelConfirmation(context, order),
                  child: const Text(
                    'Placed wrongly? Cancel Order',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: defaultPadding * 2),

                const SizedBox(height: defaultPadding * 2),
              ],
            ),
          ),
        ),
      ),

      // 2. Responsive Bottom Navigation Bar
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          double horizontalPadding = 0;
          if (constraints.maxWidth > 1200) {
            horizontalPadding = (constraints.maxWidth - 1200) / 2;
          }

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding + defaultPadding,
              vertical: defaultPadding,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        entryPointScreenRoute,
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue shopping'),
                  ),
                ),
                const SizedBox(width: defaultPadding),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        ordersScreenRoute,
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View Orders'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String title,
    String value, {
    bool isStatus = false,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding / 2),
      child: Row(
        crossAxisAlignment:
            isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: isStatus
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(value).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      value.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(value),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: isMultiLine ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'canceled':
      case 'cancelled': // Added this case
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

void _showCancelConfirmation(BuildContext context, Order order) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Cancel Order"),
      content: const Text(
          "Are you sure you want to cancel this order? This action cannot be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Keep Order"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _handleCancelOrder(context, order);
          },
          child:
              const Text("Cancel Order", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

Future<void> _handleCancelOrder(BuildContext context, Order order) async {
  // Show Loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final success = await OrdersRepository.cancelOrder(order.id);
    Navigator.pop(context); // Remove loading

    if (success) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order cancelled successfully")),
      );
      // Navigate back to home
      Navigator.pushNamedAndRemoveUntil(
        context,
        entryPointScreenRoute,
        (route) => false,
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to cancel order")),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // Remove loading if still there
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}
