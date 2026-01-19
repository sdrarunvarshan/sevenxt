import 'package:flutter/material.dart';import 'package:sevenext/constants.dart';import 'package:sevenext/route/route_constants.dart';
import '../../../models/order_model.dart';
import '../views/orders_repository.dart';
import '../views/order_status_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await OrdersRepository.getOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading orders: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await OrdersRepository.refreshOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orders refreshed')),
      );
    } catch (e) {
      debugPrint('❌ Refresh failed: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context,entryPointScreenRoute,arguments: 3),
        ),
        title: const Text("My Orders"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      )
          : _orders.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
        onRefresh: _refreshOrders,
        child: ListView.builder(
          padding: const EdgeInsets.all(defaultPadding),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            final order = _orders[index];
            return Padding(
              padding:
              const EdgeInsets.only(bottom: defaultPadding),
              child: OrderStatusCard(
                order: order,
                showDetailsButton: true,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    orderDetailsScreenRoute,
                    arguments: order.id,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            Theme.of(context).brightness == Brightness.light
                ? "assets/Illustration/EmptyState_lightTheme.png"
                : "assets/Illustration/EmptyState_darkTheme.png",
            width: MediaQuery.of(context).size.width * 0.5,
          ),
          const SizedBox(height: defaultPadding),
          Text("No Orders Yet",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            "You haven't placed any orders yet.",
            style: TextStyle(color: greyColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: defaultPadding * 2),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(
                  context, entryPointScreenRoute);
            },
            child: const Text("Start shopping"),
          ),
        ],
      ),
    );
  }
}
