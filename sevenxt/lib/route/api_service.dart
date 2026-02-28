// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '/screens/helpers/user_helper.dart';
import '../models/app_notification.dart';
import '../models/cart_model.dart';
import '../models/coupon_model.dart';
import '../models/product_model.dart';
import '../models/return_model.dart';

class ApiService {
  // CHANGE ONLY THIS LINE depending on your environment
  static const String baseUrl =
      "https://sevenxt.in/api"; // Your PC IP - removed extra space
  // For Android emulator → "http://10.0.2.2:8000"
  // For iOS simulator   → "http://127.0.0.1:8000"
  // For real device     → your PC IPv4 (192.168.x.x)

  // Token stored after login/signup
  static String? token;
  static const String forgotPasswordRequest = '/auth/forgot-password/request';
  static const String resendResetOtp = '/auth/resend-reset-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String sendVerification = '/auth/send-verification';
  static const String verifyOtpEndpoint = '/auth/verify-otp';
  static const String resetPasswordEndpoint = '/auth/reset-password';

  static Future<String> _getAuthToken() async {
    final box = await Hive.openBox('auth');
    final token = box.get('token');

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found');
    }

    return token;
  }

  static String formatPhoneNumber(String phone) {
    // Remove any non-digit characters
    String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Ensure it starts with +91 for Indian numbers if not already formatted
    if (digits.length == 10) {
      return '+91$digits';
    } else if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    } else if (!phone.startsWith('+')) {
      return '+$digits';
    }
    return phone;
  }

// Simple phone validation
  static bool isValidPhoneNumber(String phone) {
    // Remove any non-digit characters
    String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // Check if it's 10 digits (Indian mobile) or 12 digits (with 91 country code)
    return digits.length == 10 ||
        (digits.length == 12 && digits.startsWith('91'));
  }

  // Helper: Get user type from UserHelper
  static Future<String> get _userType async {
    return await UserHelper.getUserType();
  }

  static Future<List<AppNotification>> fetchNotifications() async {
    final userType = await _userType; // b2b or b2c

    // Example API call (pseudo)
    final response = await http.get(
      Uri.parse('$baseUrl/notifications?userType=$userType'),
      headers: await _headers,
    );

    // Example response handling
    final data = jsonDecode(response.body) as List;

    return data.map((e) {
      return AppNotification(
        title: e['title'],
        message: e['message'],
        time: e['time'],
        audience: _mapAudience(e['audience']),
      );
    }).toList();
  }

  static NotificationAudience _mapAudience(String value) {
    switch (value) {
      case 'b2b':
        return NotificationAudience.b2b;
      case 'b2c':
        return NotificationAudience.b2c;
      default:
        return NotificationAudience.all;
    }
  }

  // Helper: common headers
  static Future<Map<String, String>> get _headers async {
    // DEBUG: Log the token to see if it's being set correctly
    print('ApiService: Creating headers with token: $token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // POST JSON
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      uri,
      headers: await _headers,
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(response);
  }

  // POST Multipart (for file uploads – B2B documents, etc.)
  static Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
  }) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));

    request.headers.addAll(await _headers);
    request.fields.addAll(fields);
    request.files.addAll(files);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  // GET
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
    );

    return _handleResponse(response);
  }

  // GET User Profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _headers,
        body: body != null ? json.encode(body) : null,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty ? json.decode(response.body) : {};
      } else {
        throw Exception('PUT request failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.body.isNotEmpty ? json.decode(response.body) : {};
      } else {
        throw Exception('DELETE request failed: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> placeOrder(
      Map<String, dynamic> orderData) async {
    try {
      final String tokenToUse = token ?? await _getAuthToken();
      if (tokenToUse.isEmpty) {
        throw Exception('No authentication token found for placing order.');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/orders/place'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(orderData),
      );

      print('Order placement response status: ${response.statusCode}');
      print('Order placement response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to place order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in placeOrder: $e');
      rethrow;
    }
  }

  // Unified response handler with nice errors
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final int status = response.statusCode;

    if (status >= 200 && status < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Try to parse error message from FastAPI
    String message = 'Unknown error';
    try {
      final errorBody = jsonDecode(response.body);
      message = errorBody['detail'] ?? response.reasonPhrase;
    } catch (_) {
      message =
          (response.body.isNotEmpty ? response.body : response.reasonPhrase)!;
    }

    // Special case: token expired or invalid
    if (status == 401) {
      token = null; // force re-login
      // Only remove the token, DON'T clear entire box (preserves is_guest, user_email, etc.)
      Hive.box('auth').delete('token');
      throw Exception("Session expired. Please login again.");
    }

    throw HttpException("HTTP $status: $message");
  }

  // Optional: clear token on logout
  static void logout() {
    token = null;
  }

  // PRODUCT METHODS ========================================================

  // Get products with filtering
  Future<List<ProductModel>> getProducts({
    String? category,
    String? searchQuery, // Added for search functionality
    double? minPrice,
    double? maxPrice,
    String status = "Active",
    int limit = 50,
    int offset = 0,
    String? userType, // Make optional, will use UserHelper if not provided
  }) async {
    try {
      // Use provided userType or get from UserHelper
      final String currentUserType = userType ?? await _userType;

      // Build query string
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        'status': status,
        'user_type': currentUserType,
        if (category != null && category.isNotEmpty) 'category': category,
        if (searchQuery != null && searchQuery.isNotEmpty)
          'query': searchQuery, // Add search query
        if (minPrice != null) 'min_price': minPrice.toString(),
        if (maxPrice != null) 'max_price': maxPrice.toString(),
      };

      final uri =
          Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // The API returns 'products' for getProducts, 'results' for searchProducts
        // We should handle both cases here
        final List<dynamic> productsList =
            data['products'] ?? data['results'] ?? [];
        return productsList
            .map((json) =>
                ProductModel.fromJson(json, userType: currentUserType))
            .toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading products: $e');
      rethrow;
    }
  }

  Future<ProductModel> getProductById(String productId,
      {String? userType}) async {
    try {
      // Use provided userType or get from UserHelper
      final String currentUserType = userType ?? await _userType;

      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId?user_type=$currentUserType'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProductModel.fromJson(data, userType: currentUserType);
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading product by ID: $e');
      rethrow;
    }
  }

// Update the search method with all parameters
  Future<List<ProductModel>> searchProducts(
    String query, {
    int limit = 20,
    String? userType,
  }) async {
    try {
      // Use provided userType or get from UserHelper
      final String currentUserType = userType ?? await _userType;

      final response = await http.get(
        Uri.parse(
          '$baseUrl/products/search'
          '?query=${Uri.encodeComponent(query)}'
          '&limit=$limit'
          '&user_type=$currentUserType',
        ),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List results = data['results'];

        return results
            .map((json) =>
                ProductModel.fromJson(json, userType: currentUserType))
            .toList();
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error searching products: $e');
      rethrow;
    }
  }

  // Add review to product
  Future<Map<String, dynamic>> addReview(
    String productId,
    double rating,
    String? comment,
  ) async {
    try {
      final body = {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/products/$productId/review'),
        headers: await _headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to add review: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }

  // Update review
  Future<void> updateReview(
    String reviewId,
    double rating,
    String? comment,
  ) async {
    try {
      final body = {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/reviews/$reviewId'),
        headers: await _headers,
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update review: ${response.body}');
      }
    } catch (e) {
      print('Error updating review: $e');
      rethrow;
    }
  }

  // Delete review
  Future<void> deleteReview(String reviewId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reviews/$reviewId'),
        headers: await _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete review: ${response.body}');
      }
    } catch (e) {
      print('Error deleting review: $e');
      rethrow;
    }
  }

  // Get product reviews
  Future<Map<String, dynamic>> getProductReviews(
    String productId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/products/$productId/reviews?limit=$limit&offset=$offset'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading reviews: $e');
      rethrow;
    }
  }

  // Search products

  // Get products by category
  Future<List<ProductModel>> getProductsByCategory(String category, param1,
      {String? userType}) async {
    try {
      // Use provided userType or get from UserHelper
      final String currentUserType = userType ?? await _userType;

      // Use the general products endpoint with category filter
      return getProducts(category: category, userType: currentUserType);
    } catch (e) {
      print('Error loading products by category: $e');
      rethrow;
    }
  }

  // Get categories (Note: Your FastAPI doesn't have this endpoint yet)

  // Get recommended products
  Future<List<ProductModel>> getRecommendedProducts(
    String productId,
    String s, {
    int limit = 10,
    String? userType,
  }) async {
    try {
      // Use provided userType or get from UserHelper
      final String currentUserType = userType ?? await _userType;

      // Since your FastAPI doesn't have a recommendations endpoint,
      // you could return similar category products
      final product =
          await getProductById(productId, userType: currentUserType);
      if (product.category != null && product.category!.isNotEmpty) {
        return getProducts(
          category: product.category!,
          userType: currentUserType,
          limit: limit,
        );
      }
      return [];
    } catch (e) {
      print('Error loading recommended products: $e');
      return [];
    }
  }

  static Future<double> calculateShipping({
    required String deliveryPincode,
    required List<CartItem> cartItems,
  }) async {
    final payload = {
      "delivery_pincode": deliveryPincode,
      "items": cartItems.map((item) {
        final product = item.product;
        return {
          "quantity": item.quantity,
          "weight": product.weightKg,
          "length": product.lengthCm,
          "breadth": product.breadthCm,
          "height": product.heightCm,
        };
      }).toList()
    };

    final response = await http.post(
      Uri.parse('$baseUrl/shipping/delhivery/estimate'),
      headers: await _headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['shipping_fee'] as num).toDouble();
    } else {
      throw Exception("Failed to calculate shipping");
    }
  }

  // Get orders for logged-in user
  static Future<Map<String, dynamic>> getUserOrders(String userEmail) async {
    try {
      print('ApiService: Fetching orders for user: $userEmail');

      final response = await http.get(
        Uri.parse('$baseUrl/orders/user/$userEmail'),
        headers: await _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      print('ApiService: Error fetching user orders: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      final String tokenToUse = token ?? await _getAuthToken();
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $tokenToUse',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      print('ApiService: Error cancelling order: $e');
      rethrow;
    }
  }

  // ================= OTP SERVICES =================

// Send OTP (Signup / Phone verification)
  static Future<Map<String, dynamic>> sendVerificationOtp(
      String phoneNumber) async {
    return await post(
      '/auth/send-verification',
      body: {
        'phone': formatPhoneNumber(phoneNumber),
      },
    );
  }

// Verify OTP (Signup / Phone verification)
  static Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    return await post(
      '/auth/verify-otp',
      body: {
        'phone': formatPhoneNumber(phoneNumber),
        'otp': otp.trim(),
      },
    );
  }

// Request password reset OTP
  static Future<Map<String, dynamic>> requestPasswordReset(
      String phoneNumber) async {
    return await post(
      '/auth/forgot-password/request',
      body: {
        'phone': formatPhoneNumber(phoneNumber),
      },
    );
  }

// Resend password reset OTP
  static Future<Map<String, dynamic>> resendPasswordResetOtp(
      String phoneNumber) async {
    return await post(
      '/auth/resend-reset-otp',
      body: {
        'phone': formatPhoneNumber(phoneNumber),
      },
    );
  }

// Verify reset password OTP (USES SAME verify-otp ENDPOINT)
  static Future<Map<String, dynamic>> verifyPasswordResetOtp(
    String phoneNumber,
    String otp,
  ) async {
    return await post(
      '/auth/verify-otp',
      body: {
        'phone': formatPhoneNumber(phoneNumber),
        'otp': otp.trim(),
        'type': 'reset', // backend distinguishes reset OTP
      },
    );
  }

// Reset password
  static Future<Map<String, dynamic>> resetPasswordWithOtp({
    required String email,
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    return await post(
      '/auth/reset-password',
      body: {
        'email': email.trim(),
        'phone': formatPhoneNumber(phone),
        'otp': otp.trim(),
        'new_password': newPassword,
      },
    );
  }

// In your api_service.dart or ApiService class
  static Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String orderId,
  }) async {
    try {
      final token = await _getAuthToken();

      print('Verifying payment:');
      print('razorpayOrderId: $razorpayOrderId');
      print('razorpayPaymentId: $razorpayPaymentId');
      print('razorpaySignature: $razorpaySignature');
      print('orderId: $orderId');

      final response = await http.post(
        Uri.parse('$baseUrl/payment/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
          'order_id': orderId,
        }),
      );

      print('Verification response status: ${response.statusCode}');
      print('Verification response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('Verification successful: $result');
        return result;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            'Payment verification failed: ${response.statusCode} - ${errorBody['detail'] ?? response.body}');
      }
    } catch (e) {
      print('Error in verifyPayment: $e');
      rethrow;
    }
  }

  static Future<void> submitReturnRequestMultipart({
    required order,
    required product,
    required String reason,
    required int quantity,
    required String details,
    required List<XFile> images,
    required ReturnType type,
  }) async {
    final token = await _getAuthToken();

    final uri = Uri.parse(
      type == ReturnType.exchange
          ? '$baseUrl/returns/exchange'
          : '$baseUrl/returns/refund',
    );

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    // ---------- FORM FIELDS ----------
    request.fields['order_id'] = order.id.toString(); // 🔥 ADDED
    request.fields['order_item_id'] = product.orderItemId.toString();
    request.fields['reason'] = reason;
    request.fields['details'] = details;
    request.fields['type'] = type.name;

    if (type == ReturnType.exchange) {
      request.fields['variant_color'] = product.colorHex;
    }
    request.fields['quantity'] = quantity.toString();

    if (type == ReturnType.refund) {
      request.fields['payment_method'] = order.paymentMethod;
      request.fields['refund_amount'] =
          (product.price * product.quantity).toString();
    }

    // ---------- FILES ----------
    for (final xFile in images) {
      if (kIsWeb) {
        final bytes = await xFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: xFile.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('images', xFile.path),
        );
      }
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Return failed: $body');
    }
  }

  static Future<Map<String, dynamic>> getUserRefunds() async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$baseUrl/refunds/user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user refunds');
    }
  }

  static Future<Map<String, dynamic>> getUserExchanges() async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$baseUrl/exchanges/user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user exchanges');
    }
  }

  static Future<Map<String, dynamic>> getExchangesForOrder(
      String orderId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$baseUrl/exchanges/order/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch order exchanges');
    }
  }

  static Future<Map<String, dynamic>> getRefundsForOrder(String orderId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$baseUrl/returns/order/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch order refunds');
    }
  }

  // Send OTP for Order verification
  static Future<Map<String, dynamic>> sendOrderOtp(String phoneNumber) async {
    return await post(
      '/orders/send-otp',
      body: {
        'phone': phoneNumber,
      },
    );
  }

  // Verify OTP for Order
  static Future<Map<String, dynamic>> verifyOrderOtp(
    String phoneNumber,
    String otp,
  ) async {
    return await post(
      '/orders/verify-otp',
      body: {
        'phone': phoneNumber,
        'otp': otp,
        // optional but recommended for backend clarity
      },
    );
  }

  static Future<Map<String, dynamic>> applyCoupon(
      String couponCode, double subtotal) async {
    try {
      final token = await _getAuthToken(); // Ensure token is available

      final response = await http.post(
        Uri.parse('$baseUrl/coupons/apply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'coupon_code': couponCode,
          'subtotal': subtotal, // Add subtotal for discount calculation
        }),
      );

      print('Apply coupon response status: ${response.statusCode}');
      print('Apply coupon response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return responseData;
        } else {
          throw Exception(responseData['detail'] ?? 'Failed to apply coupon');
        }
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Coupon application failed');
      }
    } catch (e) {
      print('Error applying coupon: $e');
      rethrow;
    }
  }

  static Future<List<Coupon>> fetchAvailableCoupons() async {
    try {
      final token = await _getAuthToken();

      final response = await http.get(
        Uri.parse('$baseUrl/coupons/available'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Fetch coupons response status: ${response.statusCode}');
      print('Fetch coupons response body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> couponsJson = body['data'] as List<dynamic>;
          return couponsJson.map((json) => Coupon.fromJson(json)).toList();
        } else {
          throw Exception('Failed to load coupons');
        }
      } else {
        throw Exception('Failed to load coupons: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching coupons: $e');
      rethrow;
    }
  }

  // Inside your ApiService class
  static Future<Map<String, String>> getCategoryImages() async {
    final response = await http.get(
      Uri.parse('$baseUrl/category-banners'), // adjust your endpoint
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Category banners response: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final List data = json['data'];
        final Map<String, String> map = {};
        for (var item in data) {
          final category = item['category'] as String;
          final imageUrl = item['image_url'] as String;
          map[category] = imageUrl;
        }
        return map;
      }
    }

    throw Exception('Failed to load category images');
  }

  static Future<List<Map<String, dynamic>>> getHeroBanners() async {
    final response = await http.get(
      Uri.parse('$baseUrl/hero-banners'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Hero banners response: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (json['success'] == true) {
        final List data = json['data'];

        // Return a list of banner info (you can map to a model class if preferred)
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('API returned success: false');
      }
    } else {
      throw Exception('Failed to load hero banners: ${response.statusCode}');
    }
  }

  // Optional: If you want a simple list of image URLs only (like your category example)
  static Future<List<String>> getHeroBannerImageUrls() async {
    final banners = await getHeroBanners();
    return banners.map((banner) => banner['image_url'] as String).toList();
  }

  // Optional: If you want a map like position/title -> image_url
  static Future<Map<String, String>> getHeroBannerMap() async {
    final banners = await getHeroBanners();
    final Map<String, String> map = {};
    for (var banner in banners) {
      final key = banner['title']?.toString().isEmpty == true
          ? 'banner_${banner['id']}'
          : banner['title'] as String;
      map[key] = banner['image_url'] as String;
    }
    return map;
  }

  static Future<Map<String, String>> getCmsPagesMap() async {
    final response = await http.get(
      Uri.parse('$baseUrl/cms-pages'),
      headers: {
        'Authorization': 'Bearer $token', // <-- pass token here
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List pages = data['data'] ?? [];

      final Map<String, String> map = {};
      for (var page in pages) {
        final key = (page['title']?.toString().isEmpty ?? true)
            ? 'page_${page['id']}'
            : page['title'] as String;
        map[key] = page['content'] as String;
      }
      return map;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Invalid or expired token');
    } else {
      throw Exception('Failed to fetch CMS pages');
    }
  }
}
