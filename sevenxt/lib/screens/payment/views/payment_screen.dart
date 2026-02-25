// screens/payment/payment_screen.dart
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:sevenxt/components/cart_button.dart';
import 'package:sevenxt/constants.dart';
import 'package:sevenxt/models/cart_model.dart';
import 'package:sevenxt/models/coupon_model.dart';
import 'package:sevenxt/models/order_model.dart';
import 'package:sevenxt/models/product_model.dart';
import 'package:sevenxt/route/route_constants.dart';
import 'package:sevenxt/screens/helpers/user_helper.dart';
import 'package:sevenxt/screens/order/views/orders_repository.dart';

import '../../../route/api_service.dart';
import '../../../utils/razorpay_helper.dart';
import '../../address/views/addresses_screen.dart';
import '../../auth/views/components/otp_dialog.dart';
import '../../order/order_process.dart';

class PaymentScreen extends StatefulWidget {
  final Address? selectedAddress;
  final double? shippingFee;
  final Cart? cart;
  final double? stateGstAmount;
  final double? centralGstAmount;
  final double? stateGstPercent;
  final double? centralGstPercent;
  final String? userType; // ADDED: To receive userType from CartScreen

  const PaymentScreen({
    super.key,
    this.selectedAddress,
    this.shippingFee,
    this.cart,
    this.stateGstAmount,
    this.centralGstAmount,
    this.stateGstPercent,
    this.centralGstPercent,
    this.userType, // ADDED
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  String? _verifiedPaymentMethod;
  String? _pendingOrderId;
  String? _razorpayOrderId;
  String? _appliedCouponCode;
  double _couponDiscount = 0.0;
  bool _isApplyingCoupon = false;
  List<Coupon> _availableCoupons = [];
  bool _isLoadingCoupons = false;
  bool _isCalculatingSummary =
      false; // New: To manage loading state for summary

  late Razorpay _razorpay;

  Cart? _displayCart;
  double? _displayShippingFee;
  double? _displayStateGstAmount;
  double? _displayCentralGstAmount;
  double? _displayTotalGstAmount;
  double? _stateGstPercent;
  double? _centralGstPercent;
  Address? _selectedAddress;
  bool _isLoadingAddress = true;
  bool _isOrderOtpVerified = false;
  String? _resolvedUserType; // New variable to store the user type

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _displayCart = widget.cart ?? Cart();
    // Initialize these to null, they will be calculated by _recalculateOrderSummary
    _displayShippingFee = null;
    _displayStateGstAmount = null;
    _displayCentralGstAmount = null;
    _displayTotalGstAmount = null;

    _stateGstPercent = widget.stateGstPercent;
    _centralGstPercent = widget.centralGstPercent;

    _resolvedUserType = widget.userType;
    print(
        'PaymentScreen: _resolvedUserType in initState: $_resolvedUserType'); // ADDED PRINT

    // --- B2B SECURITY CHECK ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkB2BStatus();
    });

    if (widget.selectedAddress != null) {
      _selectedAddress = widget.selectedAddress;
      _isLoadingAddress = false;
      _recalculateOrderSummary(); // Recalculate if address is already provided
    } else {
      _fetchDefaultAddress(); // This will trigger _recalculateOrderSummary upon completion
    }
    _loadCoupons();
  }

  // Security Check for Direct Navigation (e.g. from Profile Screen)
  Future<void> _checkB2BStatus() async {
    try {
      final userType = await UserHelper.getUserType();
      if (userType == UserHelper.b2b) {
        final profile = await ApiService.getUserProfile();

        // Backend status values: approved, rejected, pending, suspended
        final status = profile['status']?.toString().toLowerCase();

        // Only 'approved' status is allowed
        if (status != 'approved') {
          if (mounted) {
            Navigator.of(context).pop(); // Eject user immediately

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
        }
      }
    } catch (e) {
      print("Error checking B2B status on PaymentScreen: $e");
      if (e.toString().contains("403") && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Access Restricted: Account pending or rejected."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
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
        await _recalculateOrderSummary(); // Trigger recalculation after address is set
      } else {
        setState(() {
          _selectedAddress = null;
          _isLoadingAddress = false;
        });
        await _recalculateOrderSummary(); // Trigger recalculation even if no address (will result in 0s)
      }
    } catch (e) {
      print('Error fetching address: $e');
      setState(() => _isLoadingAddress = false);
      await _recalculateOrderSummary(); // Trigger recalculation on error
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
                    '${address.address}, ${address.city}, ${address.country}'),
                trailing: address.isDefault
                    ? const Chip(label: Text('Default'))
                    : null,
                onTap: () => Navigator.pop(context, address),
              );
            },
          ),
        ).then((result) async {
          if (result != null) setState(() => _selectedAddress = result);
          await _recalculateOrderSummary(); // Trigger recalculation after address selection
        });
      }
    } catch (e) {
      print('Error fetching addresses: $e');
    }
  }

  double _getItemPrice(ProductModel product) {
    return (product.priceAfetDiscount != null &&
            product.priceAfetDiscount! < product.price)
        ? product.priceAfetDiscount!
        : product.price;
  }

  double _calculateSubtotal() {
    if (_displayCart == null || _displayCart!.items.isEmpty) return 0.0;
    return _displayCart!.items.fold<double>(
      0.0,
      (sum, item) => sum + _getItemPrice(item.product) * item.quantity,
    );
  }

  // New: Method to recalculate shipping and GST based on current cart and address
  Future<void> _recalculateOrderSummary() async {
    if (_displayCart == null || _displayCart!.items.isEmpty) {
      setState(() {
        _displayShippingFee = 0.0;
        _displayStateGstAmount = 0.0;
        _displayCentralGstAmount = 0.0;
        _displayTotalGstAmount = 0.0;
        _isCalculatingSummary = false;
      });
      return;
    }

    setState(() => _isCalculatingSummary = true);

    // Calculate GST
    double stateGstTotal = 0.0;
    double centralGstTotal = 0.0;
    for (var item in _displayCart!.items) {
      final basePrice = _getItemPrice(item.product) * item.quantity;
      stateGstTotal += basePrice * (item.product.stateGstPercent / 100);
      centralGstTotal += basePrice * (item.product.centralGstPercent / 100);
    }
    final totalGst = stateGstTotal + centralGstTotal;

    // Calculate Shipping
    double calculatedShippingFee = 0.0;
    if (_selectedAddress != null) {
      try {
        calculatedShippingFee = await ApiService.calculateShipping(
          deliveryPincode: _selectedAddress!.postalCode,
          cartItems: _displayCart!.items,
        );
      } catch (e) {
        debugPrint("Shipping calculation error in PaymentScreen: $e");
        // Optionally show a snackbar or set a flag for error
      }
    }

    setState(() {
      _displayShippingFee = calculatedShippingFee;
      _displayStateGstAmount = stateGstTotal;
      _displayCentralGstAmount = centralGstTotal;
      _displayTotalGstAmount = totalGst;
      _isCalculatingSummary = false;
    });
  }

  Future<void> _applyCoupon(String code) async {
    if (_displayCart == null) return;
    setState(() => _isApplyingCoupon = true);
    try {
      final subtotal = _calculateSubtotal();
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/coupons/apply"),
        headers: {
          "Authorization": "Bearer ${Hive.box('auth').get('token')}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"coupon_code": code, "subtotal": subtotal}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _appliedCouponCode = data['coupon_code'];
          _couponDiscount = (data['discount_amount'] as num).toDouble();
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'])));
      } else {
        throw data['detail'] ?? 'Invalid coupon';
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isApplyingCoupon = false);
    }
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoadingCoupons = true);
    try {
      final coupons = await ApiService.fetchAvailableCoupons();
      setState(() => _availableCoupons = coupons);
    } catch (e) {
      print("Coupon load error: $e");
    } finally {
      setState(() => _isLoadingCoupons = false);
    }
  }

  Future<Map<String, dynamic>> _createRazorpayOrder(String orderId) async {
    if (_displayCart == null ||
        _displayShippingFee == null ||
        _displayCart!.items.isEmpty) {
      throw Exception(
          'Cannot create Razorpay order without cart details or empty cart');
    }

    final subtotal = _calculateSubtotal();
    final double totalGst = _displayTotalGstAmount ?? 0.0;
    final totalAmount =
        subtotal + (_displayShippingFee ?? 0.0) + totalGst - _couponDiscount;

    final response = await http.post(
      Uri.parse("${ApiService.baseUrl}/payment/create-for-order/$orderId"),
      headers: {
        "Authorization": "Bearer ${Hive.box('auth').get('token')}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"amount": totalAmount}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to create Razorpay order");
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessing = true);
    try {
      final verifyResponse = await ApiService.verifyPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        orderId: _pendingOrderId ?? '',
      );
      _verifiedPaymentMethod = verifyResponse['payment_method'];
      await _executeOrderPlacement(
          paymentStatus: 'Paid', paymentId: response.paymentId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification failed')));
      setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Payment failed')));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  Future<void> _placeOrder() async {
    if (_isProcessing ||
        _displayCart == null ||
        _displayCart!.items.isEmpty ||
        _isCalculatingSummary) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No active items in cart or summary not ready')));
      return;
    }
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a shipping address'),
          backgroundColor: Colors.red));
      return;
    }

    if ((_displayShippingFee ?? 0) <= 0 && !_isCalculatingSummary) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Delivery is not available for this pincode. Please try another address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final phone = Hive.box('auth').get('user_phone');
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User phone not found. Please login again.')));
      return;
    }
    if (!_isOrderOtpVerified) {
      await _sendOrderOtp();
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // Create Razorpay order with the correct amount after all calculations and coupons
      final razorpayData = await _createRazorpayOrder(
          "temp"); // "temp" will be replaced by actual orderId from backend later
      _razorpayOrderId = razorpayData['razorpay_order_id'];
      _pendingOrderId =
          _razorpayOrderId; // Use this as the temporary order ID until confirmed

      _startRazorpay();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate payment: $e')));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendOrderOtp() async {
    final phone = Hive.box('auth').get('user_phone');
    if (phone == null) return;
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/orders/send-otp"),
        headers: {
          "Authorization": "Bearer ${Hive.box('auth').get('token')}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"phone": phone}),
      );
      if (response.statusCode == 200) {
        await _showOrderOtpDialog(phone);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Failed to send OTP")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error sending OTP: $e")));
    }
  }

  Future<void> _showOrderOtpDialog(String phone) async {
    final otp = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OtpDialog(
        phone: phone,
        onVerify: (String otp) async {
          if (otp.length != 6)
            return {"success": false, "message": "OTP must be 6 digits"};
          try {
            final response = await ApiService.verifyOrderOtp(phone, otp);
            return {
              "success": response['success'] == true,
              "message": response['message'] ?? "Invalid OTP"
            };
          } catch (e) {
            return {"success": false, "message": "OTP verification failed"};
          }
        },
      ),
    );
    if (otp != null) {
      setState(() => _isOrderOtpVerified = true);
      _placeOrder();
    }
  }

  void _startRazorpay() {
    final subtotal = _calculateSubtotal();
    final double totalGst = _displayTotalGstAmount ?? 0.0;
    final double totalAmount =
        subtotal + (_displayShippingFee ?? 0.0) + totalGst - _couponDiscount;

    final options = {
      'key': 'rzp_test_RsbvNk5QaP0H82',
      'amount': (totalAmount * 100).toInt(),
      'currency': 'INR',
      'order_id': _razorpayOrderId,
      'name': 'Sevennext',
      'description': 'Order Payment',
      'prefill': {
        'contact': Hive.box('auth').get('user_phone', defaultValue: ''),
        'email': Hive.box('auth').get('user_email', defaultValue: ''),
      },
      'notes': {'order_id': _pendingOrderId},
    };

    if (kIsWeb) {
      try {
        openRazorpay(
          options: options,
          successCallback: (dynamic jsResponse) async {
            final paymentId = jsResponse['razorpay_payment_id'] as String?;
            final orderId = jsResponse['razorpay_order_id'] as String?;
            final signature = jsResponse['razorpay_signature'] as String?;

            if (paymentId == null || orderId == null || signature == null) {
              debugPrint("Incomplete Razorpay response on web");
              setState(() => _isProcessing = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Payment response incomplete")),
              );
              return;
            }

            setState(() => _isProcessing = true);
            try {
              final verifyResponse = await ApiService.verifyPayment(
                razorpayOrderId: orderId,
                razorpayPaymentId: paymentId,
                razorpaySignature: signature,
                orderId: _pendingOrderId ?? '',
              );
              _verifiedPaymentMethod = verifyResponse['payment_method'];
              await _executeOrderPlacement(
                  paymentStatus: 'Paid', paymentId: paymentId);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment verification failed')));
              setState(() => _isProcessing = false);
            }
          },
          dismissCallback: () {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Payment cancelled or failed")),
            );
          },
        );
      } catch (e) {
        debugPrint("Razorpay web open error: $e");
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to open Razorpay on web: $e")),
        );
      }
    } else {
      try {
        _razorpay.open(options);
      } catch (e) {
        debugPrint('Razorpay mobile open error: $e');
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment initiation failed: $e")),
        );
      }
    }
  }

  Future<void> _executeOrderPlacement(
      {required String paymentStatus, String? paymentId}) async {
    try {
      final authBox = Hive.box('auth');
      final String currentUserEmail =
          authBox.get('user_email', defaultValue: '');
      final String currentUserName = authBox.get('user_name', defaultValue: '');

      final products = _displayCart!.items.map((item) {
        return OrderedProduct(
          name: item.product.title,
          imageUrl: item.product.image,
          quantity: item.quantity,
          colorHex: item.colorHex.isEmpty ? 'FFFFFFFF' : item.colorHex,
          price: item.product.price.toDouble(),
          hsnCode: item.product.hsnCode ?? '',
          weightKg: item.product.weightKg,
          lengthCm: item.product.lengthCm,
          breadthCm: item.product.breadthCm,
          heightCm: item.product.heightCm,
          productId: item.product.id,
        );
      }).toList();

      final double subtotal = _calculateSubtotal();
      final double totalPrice = subtotal +
          (_displayShippingFee ?? 0.0) +
          (_displayTotalGstAmount ?? 0.0) -
          _couponDiscount;

      // These percentages should ideally be calculated as averages or taken from a single item if homogeneous,
      // but for now, we'll pass the widget's provided ones or null if not available
      // or derive them from total GST amount if needed.
      // For a more robust solution, the backend should handle individual product GST.
      final double? orderStateGstPercent = _displayCart!.items.isNotEmpty
          ? _displayCart!.items.first.product.stateGstPercent
          : null;
      final double? orderCentralGstPercent = _displayCart!.items.isNotEmpty
          ? _displayCart!.items.first.product.centralGstPercent
          : null;

      final order = Order(
        id: _razorpayOrderId!,
        numericId: '',
        placedOn: DateTime.now(),
        orderStatus: OrderProcessStatus.ordered,
        products: products,
        totalPrice: totalPrice,
        shippingFee: _displayShippingFee ?? 0.0,
        stateGstAmount: _displayStateGstAmount ?? 0.0,
        centralGstAmount: _displayCentralGstAmount ?? 0.0,
        stateGstPercent: orderStateGstPercent,
        centralGstPercent: orderCentralGstPercent,
        customerPhone: authBox.get('user_phone', defaultValue: ''),
        customerEmail: currentUserEmail,
        customerName: currentUserName.isNotEmpty
            ? currentUserName
            : (_selectedAddress?.name ?? ''),
        customerAddressText: _selectedAddress != null
            ? '${_selectedAddress!.address}, ${_selectedAddress!.city}, ${_selectedAddress!.state} - ${_selectedAddress!.postalCode}'
            : 'No address selected',
        customerPincode: _selectedAddress?.postalCode,
        customerCity: _selectedAddress?.city,
        customerState: _selectedAddress?.state,
        userType: _resolvedUserType,
        paymentStatus: paymentStatus,
        paymentMethod: _verifiedPaymentMethod ?? 'Online',
      );
      print(
          'PaymentScreen: Order object created with userType: ${order.userType}'); // ADDED PRINT

      await OrdersRepository.addOrder(order, userType: widget.userType);
      _displayCart!.clearCart();
      if (mounted)
        Navigator.pushReplacementNamed(context, orderConfirmationScreenRoute,
            arguments: order);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Order failed: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildCouponSection() {
    final controller = TextEditingController();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Apply Coupon",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_appliedCouponCode != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Coupon $_appliedCouponCode applied",
                      style: const TextStyle(color: Colors.green)),
                  TextButton(
                      onPressed: () => setState(() {
                            _appliedCouponCode = null;
                            _couponDiscount = 0.0;
                          }),
                      child: const Text("Remove")),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                              hintText: "Enter coupon code"))),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isApplyingCoupon
                          ? null
                          : () => _applyCoupon(controller.text.trim()),
                      child: _isApplyingCoupon
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text("Apply"),
                    ),
                  )
                ],
              ),
            if (_isLoadingCoupons)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: CircularProgressIndicator()))
            else if (_availableCoupons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Column(
                children: _availableCoupons
                    .map((coupon) => ListTile(
                          title: Text(coupon.code),
                          subtitle: Text(coupon.discountType == 'fixed'
                              ? 'Flat ₹${coupon.discountValue} off'
                              : '${coupon.discountValue}% off'),
                          trailing: TextButton(
                              child: const Text("Apply"),
                              onPressed: () => _applyCoupon(coupon.code)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    if (_isLoadingAddress)
      return const Center(
          child: CircularProgressIndicator(color: kPrimaryColor));
    if (_selectedAddress == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shipping Address',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: defaultPadding / 2),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                children: [
                  const Text('No address found',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: defaultPadding / 2),
                  ElevatedButton(
                      onPressed: _selectAddress,
                      child: const Text('Add Address')),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Shipping Address',
                style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: _selectAddress, child: const Text('Change'))
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
                    Text(_selectedAddress!.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (_selectedAddress!.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: const Text('Default',
                            style: TextStyle(
                                color: kPrimaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: defaultPadding / 2),
                Text(_selectedAddress!.address,
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                    '${_selectedAddress!.city}, ${_selectedAddress!.state}, ${_selectedAddress!.country}, ${_selectedAddress!.postalCode}',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double subtotal = _calculateSubtotal();
    final bool hasCart = _displayCart != null && _displayCart!.items.isNotEmpty;
    final double stateGst = _displayStateGstAmount ?? 0.0;
    final double centralGst = _displayCentralGstAmount ?? 0.0;
    final double totalAmount = subtotal +
        (_displayShippingFee ?? 0.0) +
        stateGst +
        centralGst -
        _couponDiscount;

    return Scaffold(
      appBar: AppBar(title: const Text("Payment Method"), centerTitle: true),
      // 1. Centered and Constrained Body
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAddressSection(),
                const SizedBox(height: defaultPadding),
                if (hasCart) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Order Summary",
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: defaultPadding / 2),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Subtotal"),
                                Text("₹${subtotal.toStringAsFixed(2)}")
                              ]),
                          const SizedBox(height: 8),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Shipping"),
                                _isCalculatingSummary
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : (_displayShippingFee ?? 0) > 0
                                        ? Text(
                                            "₹${(_displayShippingFee ?? 0.0).toStringAsFixed(2)}")
                                        : const Text("Unavailable",
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold)),
                              ]),
                          const SizedBox(height: 8),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("State GST"),
                                _isCalculatingSummary
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : Text(
                                        "₹${(_displayStateGstAmount ?? 0.0).toStringAsFixed(2)}"),
                              ]),
                          const SizedBox(height: 8),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Central GST"),
                                _isCalculatingSummary
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : Text(
                                        "₹${(_displayCentralGstAmount ?? 0.0).toStringAsFixed(2)}"),
                              ]),
                          if (_couponDiscount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Coupon Discount"),
                                  Text(
                                      "-₹${_couponDiscount.toStringAsFixed(2)}",
                                      style:
                                          const TextStyle(color: Colors.green))
                                ]),
                          ],
                          const Divider(height: 24),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Total",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                Text("₹${totalAmount.toStringAsFixed(2)}",
                                    style:
                                        Theme.of(context).textTheme.titleMedium)
                              ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: defaultPadding),
                  _buildCouponSection(),
                ] else
                  Center(
                      child: Text('No active items in cart',
                          style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
          ),
        ),
      ),
      // 2. Centered Bottom Navigation Bar (Outside of body)
      bottomNavigationBar: LayoutBuilder(
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
                price: hasCart ? totalAmount : 0.0,
                title: "Place Order",
                subTitle: "Pay Now",
                press: (hasCart &&
                        _selectedAddress != null &&
                        !_isCalculatingSummary)
                    ? _placeOrder
                    : null,
                isLoading: _isProcessing || _isCalculatingSummary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  PaymentMethod(
      {required this.id,
      required this.name,
      required this.icon,
      required this.description});
}
