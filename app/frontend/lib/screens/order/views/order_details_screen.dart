import 'package:flutter/material.dart';
import 'package:sevenext/constants.dart';
import '../../../models/order_model.dart';
import '../../../models/return_model.dart';
import '../../product/views/components/returns_repository.dart';
import '../views/orders_repository.dart';
import '../order_process.dart';
import '../../../route/route_constants.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Order? _order;
  bool _isLoading = true;
  Future<List<ReturnRequest>>? _returnsFuture;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  void _loadReturns() {
    if (_order != null) {
      final queryId = _order!.id;
      setState(() {
        _returnsFuture = ReturnsRepository.getReturnsForOrder(queryId);
      });
    }
  }

  Future<void> _loadOrder() async {
    try {
      final orders = await OrdersRepository.getOrders();
      final order = orders.where((o) => o.id == widget.orderId).toList();

      if (!mounted) return;
      setState(() {
        _order = order.isNotEmpty ? order.first : null;
        _isLoading = false;
      });
      
      if (_order != null) {
        _loadReturns();
      }
    } catch (e) {
      debugPrint('❌ Order load failed: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _goToItemReturn(
    BuildContext context,
    Order order,
    OrderedProduct product,
    ReturnType type,
  ) {
    Navigator.pushNamed(
      context,
      returnRequestScreenRoute,
      arguments: {
        'order': order,
        'product': product,
        'type': type,
      },
    ).then((_) {
      _loadOrder();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    if (_order == null) {
      return const Scaffold(
        body: Center(child: Text("Order not found")),
      );
    }

    final order = _order!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<ReturnRequest>>(
        future: _returnsFuture,
        builder: (context, snapshot) {
          final existingReturns = snapshot.data ?? [];
          final isLoadingReturns = snapshot.connectionState == ConnectionState.waiting;

          return ListView(
            padding: const EdgeInsets.all(defaultPadding),
            children: [
              _summaryCard(order),
              const SizedBox(height: defaultPadding),
              
              if (isLoadingReturns)
                const Center(child: Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: CircularProgressIndicator(),
                ))
              else ...[
                ...existingReturns.map((returnReq) => _existingReturnCard(returnReq)).toList(),
                if (existingReturns.isNotEmpty) const SizedBox(height: defaultPadding),
              ],

              _addressCard(order),
              const SizedBox(height: defaultPadding),
              _itemsCard(order, existingReturns, isLoadingReturns),
              const SizedBox(height: defaultPadding),
              _priceCard(order),
              const SizedBox(height: defaultPadding),
              _paymentCard(order),
              const SizedBox(height: defaultPadding),
            ],
          );
        },
      ),
    );
  }

  Widget _existingReturnCard(ReturnRequest returnReq) {
    final isExchange = returnReq.type == ReturnType.exchange;
    final titleColor = isExchange ? Colors.orange : Colors.blue;

    return Card(
      color: titleColor.withOpacity(0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: titleColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(defaultBorderRadious),
      ),
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isExchange ? Icons.swap_horiz : Icons.undo, color: titleColor),
                const SizedBox(width: 8),
                Text(
                  isExchange ? "Exchange Requested" : "Return Requested",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Request ID: #${returnReq.id}"),
            Text("Status: ${returnReq.status.label}"),
            Text("Reason: ${returnReq.reason}"),
            Text("Date: ${returnReq.formattedDate}"),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Order #${order.id}",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  order.formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OrderStatusBadge(status: order.orderStatus),
          ],
        ),
      ),
    );
  }

  Widget _addressCard(Order order) => Card(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Delivery Address",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(order.customerAddressText),
            ],
          ),
        ),
      );

  Widget _itemsCard(Order order, List<ReturnRequest> existingReturns, bool isLoading) => Card(
    child: Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Items (${order.products.length})",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...order.products.map((p) {
            final itemReturn = existingReturns.where((r) => r.orderItemId == p.orderItemId).toList();
            return Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Qty: ${p.quantity}"),
                      if (order.orderStatus == OrderProcessStatus.delivered)
                        isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : itemReturn.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  itemReturn.first.type == ReturnType.exchange ? "Exchange Requested" : "Return Requested",
                                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                ),
                              )
                            : Row(
                                children: [
                                  TextButton(onPressed: () => _goToItemReturn(context, order, p, ReturnType.refund), child: const Text("Return")),
                                  TextButton(onPressed: () => _goToItemReturn(context, order, p, ReturnType.exchange), child: const Text("Replace")),
                                ],
                              ),
                    ],
                  ),
                ),
                const Divider(),
              ],
            );
          }),
        ],
      ),
    ),
  );

  Widget _priceCard(Order order) => Card(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("₹${order.totalPrice.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );

  Widget _paymentCard(Order order) => Card(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Payment", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Method: ${order.paymentMethod.toUpperCase()}"),
              Text("Status: ${order.paymentStatus}"),
            ],
          ),
        ),
      );
}
