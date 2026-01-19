import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sevenext/models/product_model.dart';
import 'package:sevenext/components/cart_button.dart';
import 'package:sevenext/constants.dart';
import 'package:sevenext/models/cart_model.dart';
import 'package:sevenext/route/route_constants.dart';
import 'package:intl/intl.dart';
import 'package:sevenext/route/api_service.dart';
import 'package:sevenext/screens/order/views/orders_screen.dart';
import '/screens/order/views/orders_repository.dart';
import 'package:sevenext/models/order_model.dart';
import '../../order/order_process.dart';
import '../../helpers/user_helper.dart';
import 'package:sevenext/screens/address/views/addresses_screen.dart';
// Import shared Address model
import 'package:sevenext/models/cart_model.dart'; // Import Cart


class CartScreen extends StatefulWidget {
  final bool showBackButton;
  final String? userType;
  const CartScreen({super.key, this.showBackButton = true ,
    this.userType});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Cart _cart = Cart();
  double _shippingFee = 0.0;
  bool _isCalculatingShipping = false;

  Address? _selectedAddress;
  bool _isLoadingAddress = true;
  late String _resolvedUserType;


  @override
  void initState(){
    super.initState();
    _initCartScreen();
    // fallback
    _fetchDefaultAddress();
  }
  Future<void> _initCartScreen() async {
    if (widget.userType != null) {
      _resolvedUserType = widget.userType!;
      print('CartScreen: _resolvedUserType from widget: $_resolvedUserType'); // ADDED PRINT
    } else {
      _resolvedUserType = await UserHelper.getUserType();
      print('CartScreen: _resolvedUserType from UserHelper: $_resolvedUserType'); // ADDED PRINT
    }

    if (!mounted) return;
    setState(() {});
    await _fetchDefaultAddress();
  }


  Future<void> _fetchDefaultAddress() async {
    setState(() => _isLoadingAddress = true);

    try {
      final response = await ApiService.get('/users/addresses');
      final List data = response['data'];

      if (data.isNotEmpty) {
        final defaultAddress = data.firstWhere(
          (addr) => addr['is_default'] == 1 || addr['is_default'] == true,
          orElse: () => data.first,
        );

        setState(() {
          _selectedAddress = Address.fromJson(defaultAddress);
          _isLoadingAddress = false;
        });
        // *** FIX START: Calculate shipping fee when default address is loaded ***
        _calculateShipping();
        // *** FIX END ***
      } else {
        setState(() {
          _selectedAddress = null;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      print('Error fetching address: $e');
      setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _selectAddress() async {
    try {
      final response = await ApiService.get('/users/addresses');
      final List<dynamic> addressesList = response['data'];

      if (addressesList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No addresses available')),
          );
        }
        return;
      }


      final addresses = addressesList.map((addr) => Address.fromJson(addr)).toList();

      if (mounted) {
        showModalBottomSheet<Address>(
          context: context,
          builder: (context) => ListView.builder(
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return ListTile(
                title: Text(address.name),
                subtitle: Text(
                  '${address.address}, ${address.city}, ${address.country}',
                ),
                trailing: address.isDefault
                    ? const Chip(label: Text('Default'))
                    : null,
                onTap: () {
                  Navigator.pop(context, address);
                },
              );
            },
          ),
        ).then((result) {
          if (result != null) {
            setState(() {
              _selectedAddress = result;
            });
          }
          _calculateShipping();

        });
      }
    } catch (e) {
      print('Error fetching addresses: $e');
    }
  }


  Widget _buildAddressSection() {
    if (_isLoadingAddress) {
      return const Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    if (_selectedAddress == null) {
      return Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shipping Address',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: defaultPadding / 2),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  children: [
                    const Text(
                      'No address found',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: defaultPadding / 2),
                    ElevatedButton(
                      onPressed: _selectAddress,
                      child: const Text('Add Address'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping Address',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: _selectAddress,
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding / 2),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedAddress!.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_selectedAddress!.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Text(
                    _selectedAddress!.address,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedAddress!.city},${_selectedAddress!.state} ${_selectedAddress!.country}, ${_selectedAddress!.postalCode}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getItemPrice(ProductModel product) {
    return (product.priceAfetDiscount != null &&
            product.priceAfetDiscount! < product.price)
        ? product.priceAfetDiscount!
        : product.price;
  }
  double _calculateItemStateGST(ProductModel product, int quantity) {
    final basePrice = _getItemPrice(product).toDouble() * quantity;
    return basePrice * (product.stateGstPercent / 100);
  }

  double _calculateItemCentralGST(ProductModel product, int quantity) {
    final basePrice = _getItemPrice(product).toDouble() * quantity;
    return basePrice * (product.centralGstPercent / 100);
  }

  Map<String, double> _calculateTotalGST() {
    double stateGstTotal = 0.0;
    double centralGstTotal = 0.0;

    for (var item in _cart.items) {
      stateGstTotal += _calculateItemStateGST(item.product, item.quantity);
      centralGstTotal += _calculateItemCentralGST(item.product, item.quantity);
    }
    return {
      'state_gst': stateGstTotal,
      'central_gst': centralGstTotal,
      'total_gst': stateGstTotal + centralGstTotal,
    };
  }
  Future<void> _calculateShipping() async {
    if (_selectedAddress == null || _cart.items.isEmpty) return;

    setState(() => _isCalculatingShipping = true);

    try {
      final fee = await ApiService.calculateShipping(
        deliveryPincode: _selectedAddress!.postalCode,
        cartItems: _cart.items,
      );

      setState(() {
        _shippingFee = fee;
        _isCalculatingShipping = false;
      });


    } catch (e) {
      setState(() => _isCalculatingShipping = false);
      print("Shipping error: $e");
    }
  }
  // ------------------ HIVE SNAPSHOT HELPERS ------------------





  @override
  Widget build(BuildContext context) {
    // Calculate subtotal and total here, before returning the UI
    final gstMap = _calculateTotalGST(); // Get the GST map
    final double stateGstTotal = gstMap['state_gst'] ?? 0.0;
    final double centralGstTotal = gstMap['central_gst'] ?? 0.0;
    final double totalGst = gstMap['total_gst'] ?? 0.0;
    double subtotal = _cart.items.fold<double>(
      0.0,
          (sum, item) => sum + _getItemPrice(item.product) * item.quantity,
    );

    double grandTotal = subtotal + totalGst + _shippingFee;

    double stateGstPercent = 0;
    double centralGstPercent = 0;

    if (_cart.items.isNotEmpty) {
      stateGstPercent = _cart.items.first.product.stateGstPercent;
      centralGstPercent = _cart.items.first.product.centralGstPercent;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        centerTitle: true,
        leading: widget.showBackButton ? const BackButton() : null,
      ),
      body: Column(
        children: [
          _buildAddressSection(),
          Expanded(
            child: _cart.items.isEmpty
                ? Center(
                    child: Text(
                      "Your cart is empty!",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(defaultPadding / 2),
                    itemCount: _cart.items.length,
                    itemBuilder: (context, index) {
                      final cartItem = _cart.items[index];
                      final ProductModel product = cartItem.product;
                      final double itemPrice = _getItemPrice(product) as double;
                      return Card(
                        margin: const EdgeInsets.only(bottom: defaultPadding),
                        child: Padding(
                          padding: const EdgeInsets.all(defaultPadding),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(product.image),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: defaultPadding),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: defaultPadding / 4),
                                    Text(
                                      '₹${itemPrice.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: kPrimaryColor),
                                    ),
                                    const SizedBox(height: defaultPadding / 4),
                                    Row(
                                      children: [
                                        Text('Qty: ${cartItem.quantity}'),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _cart.removeItem(cartItem);
                                  });
                                  _calculateShipping();

                                },
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_cart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('₹${_cart.items.fold<double>(0.0, (sum, item) => sum + _getItemPrice(item.product) * item.quantity).toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: defaultPadding / 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Shipping Fee'),
                      _isCalculatingShipping
                          ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text('₹${_shippingFee.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: defaultPadding / 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('State GST'),
                      Text('₹${stateGstTotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: defaultPadding / 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Central GST'),
                      Text('₹${centralGstTotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: defaultPadding / 4),
                  const Divider(height: defaultPadding * 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Price',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₹${grandTotal.toStringAsFixed(2)}',
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
        ],
      ),
      bottomNavigationBar: _cart.items.isNotEmpty
          ? CartButton(
        price: _cart.items.fold<double>(0.0, (sum, item) => sum + _getItemPrice(item.product) * item.quantity) +
            _shippingFee +
            totalGst, // Add GST here
        title: "Proceed to Checkout",
        press: () {
          if (_selectedAddress == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select an address'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Navigate to Payment Screen
          Navigator.pushNamed(
            context,
            paymentScreenRoute,
            arguments: {
              'selectedAddress': _selectedAddress,
              'shippingFee': _shippingFee,
              'cart': _cart,
              'userType': _resolvedUserType,
              'stateGstAmount': stateGstTotal, // ADD THIS - pass state GST
              'centralGstAmount': centralGstTotal,
              'stateGstPercent': stateGstPercent,
              'centralGstPercent': centralGstPercent,
              'originalPrice': subtotal,// ADD THIS - pass central GST
              // ADD THIS
             },
          );
          print('CartScreen: Navigating to PaymentScreen with userType: $_resolvedUserType'); // ADDED PRINT
        },
        isLoading: _isCalculatingShipping,
      )
          : null,
    );
  }

}
