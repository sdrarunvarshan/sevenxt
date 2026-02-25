import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../order_process.dart';
import '/models/order_model.dart';
import 'package:sevenxt/route/api_service.dart';
import 'package:http/http.dart' as http;
import '../../helpers/user_helper.dart'; // Import UserHelper

class OrdersRepository {

  // Get all orders - FROM BACKEND IF LOGGED IN, OTHERWISE LOCAL
  static Future<List<Order>> getOrders() async {
    try {
      // Check if user is guest
      final authBox = Hive.box('auth');
      final isGuest = authBox.get('is_guest');

      if (isGuest == true) {
        // Guest user - no local storage, return empty list
        print('Guest user, returning empty order list.');
        return [];
      }

      // User is logged in - fetch from backend
      return await _fetchOrdersFromBackend();
    } catch (e) {
      print('Error getting orders: $e');
      return [];
    }
  }

  // Check if user is guest
  static Future<bool> _isGuestUser() async {
    try {
      final authBox = Hive.box('auth');
      final isGuest = authBox.get('is_guest');
      return isGuest == true;
    } catch (e) {
      return true; // Default to guest on error
    }
  }

  // Get user email from Hive
  static Future<String> _getUserEmail() async {
    try {
      final authBox = Hive.box('auth');
      // Check for 'email' key, as 'user_email' might be the one that's missing/empty
      final email = authBox.get('user_email', defaultValue: '');
      return email;
    } catch (e) {
      print('Error getting user email: $e');
      return '';
    }
  }

  // Fetch orders from backend API for logged-in user
  static Future<List<Order>> _fetchOrdersFromBackend() async {
    try {
      final userEmail = await _getUserEmail();

      if (userEmail.isEmpty) {
        print('User email not found in Hive during order fetch. Skipping backend call.');
        return [];
      }

      print('Fetching orders from backend for email: $userEmail');

      // Call backend API
      final response = await ApiService.getUserOrders(userEmail);

      // Debug: Print the raw response
      print('Raw backend response: $response');

      if (response is Map && response.containsKey('success') && response['success'] == true) {
        List<Order> orders = [];

        if (response.containsKey('orders') && response['orders'] is List) {
          print('Found ${response['orders'].length} orders in response');

          for (var orderData in response['orders']) {
            print('Order data structure: ${orderData.keys}');
            try {
              final order = await _parseOrderFromBackend(orderData);
              if (order != null) {
                orders.add(order);
              }
            } catch (e) {
              print('Error parsing order: $e');
              print('Problematic order data: $orderData');
            }
          }
        }

        print('Fetched ${orders.length} orders from backend');
        return orders;
      } else {
        print('Failed to fetch orders from backend. Response: $response');
        return [];
      }
    } catch (e) {
      print('Error fetching from backend: $e');
      return [];
    }
  }


  // Parse backend order data to Order model
  static Future<Order?> _parseOrderFromBackend(Map<String, dynamic> orderData) async {
    try {
      print('Parsing order data using Order.fromJson');

      // Use the Order.fromJson factory constructor
      return Order.fromJson(orderData);
    } catch (e) {
      print('❌ Error parsing order using Order.fromJson: $e');
      print('Problematic order data: $orderData');

      // Fallback to manual parsing if Order.fromJson fails
      try {
        print('Attempting manual parsing as fallback...');

        // Parse date
        DateTime placedOn = DateTime.now();
        if (orderData['date'] != null) {
          if (orderData['date'] is DateTime) {
            placedOn = orderData['date'];
          } else if (orderData['date'] is String) {
            try {
              placedOn = DateTime.parse(orderData['date']);
            } catch (e) {
              print('Error parsing date string: ${orderData['date']}');
            }
          }
        }

        String _normalizePaymentMethod(String? method) {
          if (method == null || method.trim().isEmpty) return 'unknown';

          final m = method.toLowerCase().trim();

          if (m.contains('upi')) return 'upi';
          if (m.contains('net') || m.contains('banking')) return 'netbanking';
          if (m.contains('card')) return 'card';
          if (m.contains('wallet')) return 'wallet';
          if (m.contains('emi')) return 'emi';
          if (m.contains('cod') || m.contains('cash')) return 'cod';

          return m;
        }

        // Parse products using the updated method
        final products = await _parseProductsFromBackend(orderData);

        // Parse status
        final backendStatus = orderData['status']?.toString().toLowerCase() ?? 'processing';
        final mainStatus = _parseOrderStatus(backendStatus);

        // Debug print to see the raw payment method
        final rawPaymentMethod = orderData['payment_method'] ??
            orderData['paymentMethod'] ??
            orderData['payment_mode'];
        print('Fallback: Raw payment method from backend: $rawPaymentMethod');

        // Directly assign the normalized value
        final paymentMethod = _normalizePaymentMethod(rawPaymentMethod?.toString());

        // Parse payment status
        String paymentStatus =
            orderData['payment_status']?.toString() ??
                orderData['paymentStatus']?.toString() ??
                'pending';

        // Parse GST amounts from backend or use defaults
        final double stateGstAmount = (orderData['state_gst_amount'] as num?)?.toDouble() ?? 0.0;
        final double centralGstAmount = (orderData['central_gst_amount'] as num?)?.toDouble() ?? 0.0;
        
        // 🔥 NEW: Parse GST percentages
        final double stateGstPercent = (orderData['sgst_percentage'] as num?)?.toDouble() ?? 0.0;
        final double centralGstPercent = (orderData['cgst_percentage'] as num?)?.toDouble() ?? 0.0;

        return Order(
          id: orderData['order_id']?.toString() ?? '',
          numericId: orderData['id']?.toString() ?? '', // Assign numericId
          placedOn: placedOn,
          orderStatus: mainStatus,

          products: products,
          totalPrice: _parsePrice(orderData['amount']),
          shippingFee: (orderData['shipping_fee'] as num?)?.toDouble() ?? 0.0,
          stateGstAmount: stateGstAmount,
          centralGstAmount: centralGstAmount,
          stateGstPercent: stateGstPercent, // Fixed percentages in fallback
          centralGstPercent: centralGstPercent, // Fixed percentages in fallback
          customerEmail: orderData['email']?.toString() ?? '',
          customerName: orderData['customer_name']?.toString() ?? '', // ADDED
          customerPhone: orderData['phone']?.toString() ?? '',
          customerAddressText: orderData['address']?.toString() ?? '',
          paymentMethod: paymentMethod,
          paymentStatus: paymentStatus,
          userType: orderData['type']?.toString(),
        );
      } catch (fallbackError) {
        print('❌ Fallback parsing also failed: $fallbackError');
        return null;
      }
    }
  }

  static OrderProcessStatus _getDeliveredStatus(String backendStatus) {
    switch (backendStatus.toUpperCase().trim()) {
      case 'DELIVERED':
        return OrderProcessStatus.delivered;

      case 'CANCELLED':
        return OrderProcessStatus.cancelled;

      default:
        return OrderProcessStatus.error;
    }
  }


  // Helper method to create an Order with updated statuses
  static Order _updateOrderStatus(Order baseOrder, String backendStatus) {
    print('Available OrderProcessStatus values: ${OrderProcessStatus.values}');
    final OrderProcessStatus mainStatus = _parseOrderStatus(backendStatus);
    return baseOrder;
  }

  // Parse price from backend
  static double _parsePrice(dynamic amount) {
    if (amount == null) return 0.0;

    if (amount is int) {
      return amount.toDouble();
    } else if (amount is double) {
      return amount;
    } else if (amount is String) {
      return double.tryParse(amount) ?? 0.0;
    }

    return 0.0;
  }

  // Parse products from backend data
  static Future<List<OrderedProduct>> _parseProductsFromBackend(
      Map<String, dynamic> orderData) async {
    try {
      if (orderData.containsKey('order_items') &&
          orderData['order_items'] is List) {
        return (orderData['order_items'] as List)
            .map((item) => OrderedProduct.fromJson(item))
            .toList();
      }

      if (orderData.containsKey('products') &&
          orderData['products'] is List) {
        return (orderData['products'] as List).map((item) {
          return OrderedProduct(
            orderItemId: item['id'],
            name: item['name'] ?? 'Product',
            imageUrl: item['imageUrl'] ?? '',
            colorHex: item['colorHex'] ?? 'FFFFFFFF',
            quantity: int.tryParse(item['quantity'].toString()) ?? 1,
            price: (item['price'] as num?)?.toDouble(),
            status: 'ordered',
            hsnCode: item['hsnCode'] ?? '',
            weightKg: (item['weightKg'] as num?)?.toDouble(),
            lengthCm: (item['lengthCm'] as num?)?.toDouble(),
            breadthCm: (item['breadthCm'] as num?)?.toDouble(),
            heightCm: (item['heightCm'] as num?)?.toDouble(),
            productId: item['product_id']?.toString() ??
                item['id']?.toString(),
          );
        }).toList();
      }
    } catch (e) {
      print('❌ PRODUCT PARSE ERROR: $e');
      print('Order data: $orderData');
    }

    return [];
  }


  // Helper to parse status string to enum
  static OrderProcessStatus _parseOrderStatus(String status) {
    if (status == null) return OrderProcessStatus.error;

    switch (status.toUpperCase().trim()) {
      case "Ordered":
        return OrderProcessStatus.ordered;

      case 'PROCESSING':
      case 'AWB_GENERATED':
        return OrderProcessStatus.awbGenerated;

      case 'PICKUP_REQUESTED':
        return OrderProcessStatus.pickupRequested;

      case 'PICKED_UP':
        return OrderProcessStatus.pickedUp;

      case 'IN_TRANSIT':
        return OrderProcessStatus.inTransit;

      case 'OUT_FOR_DELIVERY':
        return OrderProcessStatus.outForDelivery;

      case 'DELIVERED':
        return OrderProcessStatus.delivered;

      case 'FAILED':
        return OrderProcessStatus.failed;

      case 'CANCELLED':
        return OrderProcessStatus.cancelled;

      case 'RTO':
        return OrderProcessStatus.rto;

      case 'RTO_DELIVERED':
        return OrderProcessStatus.rtoDelivered;

      default:
        return OrderProcessStatus.error;
    }
  }


  // Add a new order - SAVES TO BOTH LOCAL AND BACKEND
  static Future<void> addOrder(Order newOrder, {String? userType}) async {
    try {
      final isGuest = await _isGuestUser();

      // If user is logged in, save to backend
      if (!isGuest) {
        final userEmail = await _getUserEmail(); // Get email first
        await _saveOrderToBackend(newOrder, userEmail, userType: userType); // Pass both arguments
        print('Order saved to backend successfully');
      }
      else {
        print('Guest user, order not saved locally as SharedPreferences is removed.');
      }
    } catch (e) {
      print('Error saving order: $e');
      rethrow;
    }
  }

  // Helper method to save order to backend
  static Future<void> _saveOrderToBackend(Order order, String userEmailFromHive, {String? userType}) async {
    try {
      // Get user info from Hive
      final userEmail = await _getUserEmail();
      // Ensure the correct userType is passed. If userType is null, fallback to order.userType, then to UserHelper.getUserType()
      final finalUserType = userType ?? order.userType ?? await UserHelper.getUserType();


      // Determine the email to send
      String emailToSend = userEmailFromHive.isNotEmpty ? userEmailFromHive : userEmail;
      if (emailToSend.isEmpty) {
        emailToSend = order.customerEmail;
        if (emailToSend.isEmpty) {
          print('WARNING: Customer email is empty. Cannot save to backend.');
          throw Exception("Customer email is missing. Cannot place order.");
        }
      }

      // Log payment method for debugging
      print('Saving order with payment method: ${order.paymentMethod}, status: ${order.paymentStatus}');

      // Convert Order model to the format expected by FastAPI
      final orderData = {
        'order_id': order.id,
        'id': order.numericId,
        'placed_on': _formatDateForBackend(order.placedOn),
        'order_status': order.orderStatus.toString().split('.').last,
        'products': order.products.map((product) => {
           'name': product.name,
          'price' : product.price,
          'imageUrl': product.imageUrl,
          'quantity': product.quantity,
          'colorHex': product.colorHex,
          'hsnCode': product.hsnCode,
          'weightKg': product.weightKg,
          'lengthCm': product.lengthCm,
          'breadthCm': product.breadthCm,
          'heightCm': product.heightCm,
          'product_id': product.productId, // 🔥 ADD THIS
        }).toList(),
        'total_price': order.totalPrice,
        'address': order.customerAddressText,
        'city': order.customerCity ?? '', 
        'state': order.customerState ?? '',
        'pincode': order.customerPincode ?? '',
        'phone': order.customerPhone,
        'shipping_fee': order.shippingFee,
        'sgst_percentage': order.stateGstPercent ?? 0.0,
        'cgst_percentage': order.centralGstPercent ?? 0.0,
        'state_gst_amount': order.stateGstAmount,
        'central_gst_amount': order.centralGstAmount,
        'customer_email': emailToSend,
        'customer_name': order.customerName, // ADDED
        'customer_address_text': order.customerAddressText,
        'customer_type': finalUserType, // Use the resolved finalUserType
        'payment_method': order.paymentMethod, 
        'payment_status': order.paymentStatus, 
      };

      // Send to backend
      final response = await ApiService.placeOrder(orderData);
      print('Backend response: $response');
    } catch (e) {
      print('Failed to save order to backend: $e');
      rethrow;
    }
  }

  // Get user type from Hive (Modified to use UserHelper for consistency)
  static Future<String> _getUserType() async {
    try {
      return await UserHelper.getUserType();
    } catch (e) {
      print('Error getting user type from UserHelper: $e');
      return 'b2c'; // Fallback to 'b2c' on error
    }
  }

  // Helper to format date for backend (DD/MM/YYYY format)
  static String _formatDateForBackend(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  // Delete an order by ID
  static Future<bool> deleteOrder(String orderId) async {
    try {
      final isGuest = await _isGuestUser();

      if (!isGuest) {
        print('TODO: Implement backend deletion for order $orderId');
        return false; 
      }
      else {
        print('Guest user, no local order $orderId to delete.');
        return false;
      }
    } catch (e) {
      print('Error deleting order: $e');
      return false;
    }
  }

  // Force refresh from backend (ignores local cache)!
  static Future<List<Order>> refreshOrders() async {
    try {
      final isGuest = await _isGuestUser();

      if (!isGuest) {
        return await _fetchOrdersFromBackend();
      }
      else {
        print('Guest user, no local cache to refresh, returning empty order list.');
        return [];
      }
    } catch (e) {
      print('Error refreshing orders: $e');
      return [];
    }
  }
}
