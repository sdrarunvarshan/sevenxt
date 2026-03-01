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
  late String _resolvedUserType;

  @override
  void initState() {
    super.initState();
    _initCartScreen();
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
    _fetchDefaultAddress();
  }

  Future<void> _fetchDefaultAddress() async {
    try {
      final response = await ApiService.get('/users/addresses');
      final List data = response['data'];

      if (data.isNotEmpty) {
        final defaultAddress = data.firstWhere(
          (addr) => addr['is_default'] == 1 || addr['is_default'] == true,
          orElse: () => data.first,
        );

        if (mounted) {
          setState(() {
            _selectedAddress = Address.fromJson(defaultAddress);
          });
          _calculateShipping();
        }
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
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
    if (_selectedAddress != null && _shippingFee <= 0 && !_isCalculatingShipping) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Delivery is not available for this pincode. Please try another address.'),
          backgroundColor: errorColor,
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
                  backgroundColor: errorColor,
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
                backgroundColor: errorColor,
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
                                        color: errorColor),
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
            : Text(
                _selectedAddress == null
                    ? 'Calculated at checkout'
                    : '₹${_shippingFee.toStringAsFixed(2)}',
                style: _selectedAddress == null
                    ? const TextStyle(fontStyle: FontStyle.italic, color: greyColor)
                    : null,
              ),
      ],
    );
  }
}

