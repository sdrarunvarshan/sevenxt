import 'package:flutter/material.dart';
import 'package:sevenxt/components/cart_button.dart';
import 'package:sevenxt/constants.dart';
import 'package:sevenxt/models/cart_model.dart';
import 'package:sevenxt/models/product_model.dart';
import 'package:sevenxt/route/api_service.dart';
import 'package:sevenxt/route/route_constants.dart';
import 'package:sevenxt/screens/address/views/addresses_screen.dart';

import '../../../components/skleton/skelton.dart';
import '../../helpers/user_helper.dart';

class CartScreen extends StatefulWidget {
  final bool showBackButton;
  final bool isTab;
  final String? userType;
  
  const CartScreen({
    super.key,
    this.showBackButton = true,
    this.isTab = false,
    this.userType
  });

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
  void initState() {
    super.initState();
    _initCartScreen();
    _fetchDefaultAddress();
  }

  Future<void> _initCartScreen() async {
    if (widget.userType != null) {
      _resolvedUserType = widget.userType!;
      print(
          'CartScreen: _resolvedUserType from widget: $_resolvedUserType');
    } else {
      _resolvedUserType = await UserHelper.getUserType();
      print(
          'CartScreen: _resolvedUserType from UserHelper: $_resolvedUserType');
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
        _calculateShipping();
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

      final addresses =
          addressesList.map((addr) => Address.fromJson(addr)).toList();

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
      return Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Skeleton(height: 100, width: double.infinity),
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

  bool _isCheckingStatus = false;

  Future<void> _proceedToCheckout() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_shippingFee <= 0 && !_isCalculatingShipping) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Delivery is not available for this pincode. Please try another address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCheckingStatus = true);

    try {
      final userType = await UserHelper.getUserType();

      if (userType == UserHelper.b2b) {
        try {
          final profile = await ApiService.getUserProfile();
          print("B2B Profile Check: $profile");

          final status = profile['status']?.toString().toLowerCase();

          if (status != 'approved') {
            if (mounted) {
              String message = "Your B2B account is ";
              if (status == 'pending') {
                message += "pending approval.";
              } else if (status == 'rejected') {
                message += "rejected.";
              } else if (status == 'suspended') {
                message += "suspended.";
              } else {
                message += "not approved (status: ${status ?? 'unknown'}).";
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            return;
          }
        } catch (e) {
          print("B2B Check Error: $e");
          String errorMessage = "Could not verify B2C/B2B status.";
          if (e.toString().contains("403")) {
            errorMessage = "B2B account pending approval or rejected.";
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      paymentScreenRoute,
      arguments: {
        'selectedAddress': _selectedAddress,
        'shippingFee': _shippingFee,
        'cart': _cart,
        'userType': _resolvedUserType,
        'stateGstAmount': _calculateTotalGST()['state_gst'],
        'centralGstAmount': _calculateTotalGST()['central_gst'],
        'stateGstPercent': _cart.items.isNotEmpty
            ? _cart.items.first.product.stateGstPercent
            : 0.0,
        'centralGstPercent': _cart.items.isNotEmpty
            ? _cart.items.first.product.centralGstPercent
            : 0.0,
        'originalPrice': _cart.items.fold<double>(
          0.0,
          (sum, item) => sum + _getItemPrice(item.product) * item.quantity,
        ),
      },
    );
    print(
        'CartScreen: Navigating to PaymentScreen with userType: $_resolvedUserType');
  }

  @override
  Widget build(BuildContext context) {
    final gstMap = _calculateTotalGST();
    final double stateGstTotal = gstMap['state_gst'] ?? 0.0;
    final double centralGstTotal = gstMap['central_gst'] ?? 0.0;
    final double totalGst = gstMap['total_gst'] ?? 0.0;

    double subtotal = _cart.items.fold<double>(
      0.0,
      (sum, item) => sum + _getItemPrice(item.product) * item.quantity,
    );

    double grandTotal = subtotal + totalGst + _shippingFee;

    return Scaffold(
      appBar: widget.isTab
          ? null
          : AppBar(
              title: const Text('Cart'),
              centerTitle: true,
              leading: widget.showBackButton ? const BackButton() : null,
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
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
                          final double itemPrice = _getItemPrice(product);
                          return Card(
                            margin:
                                const EdgeInsets.only(bottom: defaultPadding),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(
                                            height: defaultPadding / 4),
                                        Text(
                                          '₹${itemPrice.toStringAsFixed(2)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(color: kPrimaryColor),
                                        ),
                                        const SizedBox(
                                            height: defaultPadding / 4),
                                        Text('Qty: ${cartItem.quantity}'),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(
                                          () => _cart.removeItem(cartItem));
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
                    children: [
                      _buildSummaryRow('Subtotal', subtotal),
                      _buildShippingRow(),
                      _buildSummaryRow('State GST', stateGstTotal),
                      _buildSummaryRow('Central GST', centralGstTotal),
                      const Divider(height: defaultPadding * 2),
                      _buildSummaryRow('Total Price', grandTotal, isBold: true),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _cart.items.isNotEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                double horizontalPadding = 0;
                if (constraints.maxWidth > 1200) {
                  horizontalPadding = (constraints.maxWidth - 1200) / 2;
                }

                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding + defaultPadding,
                      vertical: defaultPadding,
                    ),
                    child: CartButton(
                      price: grandTotal,
                      title: "Proceed to Checkout",
                      press: _proceedToCheckout,
                      isLoading: _isCalculatingShipping || _isCheckingStatus,
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: defaultPadding / 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text('₹${value.toStringAsFixed(2)}',
              style: isBold
                  ? const TextStyle(
                      fontWeight: FontWeight.bold, color: kPrimaryColor)
                  : null),
        ],
      ),
    );
  }

  Widget _buildShippingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Shipping Fee'),
        _isCalculatingShipping
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text('₹${_shippingFee.toStringAsFixed(2)}'),
      ],
    );
  }
}
