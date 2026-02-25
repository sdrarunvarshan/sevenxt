import 'dart:convert';
import '../screens/order/order_process.dart';

class OrderedProduct {
  final int? orderItemId;
  final String name;
  final String imageUrl;
  final int quantity;
   final String? productId; // 🔥 ADD THIS
  final String colorHex;
  final String hsnCode;
  final double? price;
  final String? status;
  final double? weightKg;
  final double? lengthCm;
  final double? breadthCm;
  final double? heightCm;


  OrderedProduct({
    this.orderItemId,
    required this.name,

    required this.imageUrl,
    required this.quantity,
    required this.colorHex,
    this.price,
    this.status,
    this.hsnCode = '',
    this.weightKg,
    this.lengthCm,
    this.breadthCm,
    this.heightCm,
    this.productId, // 🔥 ADD
  });

  factory OrderedProduct.fromJson(Map<String, dynamic> json) {
    int quantity = 1;
    if (json['quantity'] is int) {
      quantity = json['quantity'];
    } else if (json['quantity'] is String) {
      quantity = int.tryParse(json['quantity']) ?? 1;
    } else if (json['quantity'] is double) {
      quantity = (json['quantity'] as double).toInt();
    }

    double? price;
    if (json['price'] is num) {
      price = (json['price'] as num).toDouble();
    } else if (json['price'] is String) {
      price = double.tryParse(json['price']);
    }
    int orderItemId = 0;
    if (json['order_item_id'] != null) {
      if (json['order_item_id'] is int) {
        orderItemId = json['order_item_id'];
      } else if (json['order_item_id'] is String) {
        orderItemId = int.tryParse(json['order_item_id']) ?? 0;
      }
    }
    else if (json['id'] != null) {
      if (json['id'] is int) {
        orderItemId = json['id'];
      } else if (json['id'] is String) {
        orderItemId = int.tryParse(json['id']) ?? 0;
      }
    }

    return OrderedProduct(

      orderItemId: orderItemId,
      name: json['name']?.toString() ?? 'Product',
      imageUrl: json['imageUrl']?.toString() ?? '',
      quantity: quantity,
      colorHex: json['colorHex']?.toString() ?? 'FFFFFFFF',
      price: price,
      status: json['status'],
      hsnCode: json['hsnCode']?.toString() ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      lengthCm: (json['lengthCm'] as num?)?.toDouble(),
      breadthCm: (json['breadthCm'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      productId: json['product_id']?.toString() ??
          json['id']?.toString(), // 🔥 ADD THIS
    );
  }
}

class Order {
  final String id; // This is the order_id string (e.g. order_S28GV5gxE7JMgG)
  final String numericId; // This is the DB primary key (e.g. 82)
  final DateTime placedOn;
  final String customerPhone;
  final OrderProcessStatus orderStatus;
   final double stateGstAmount;
  final double centralGstAmount;
  final double? stateGstPercent;
  final double? centralGstPercent;
  final List<OrderedProduct> products;
  final double totalPrice;
  final double shippingFee;
  final String customerEmail;
  final String customerAddressText;
  final String? customerCity;
  final String? customerState;
  final String customerName;
  final String? customerPincode;
  final String paymentMethod;
  final String paymentStatus;
  final String? userType;

  Order({
    required this.id,
    required this.numericId,
    required this.customerName,
    required this.customerPhone,
    required this.placedOn,
    required this.orderStatus,

    required this.stateGstAmount,
    required this.centralGstAmount,

    this.stateGstPercent,
    this.centralGstPercent,
    required this.products,
    required this.totalPrice,
    required this.shippingFee,
    required this.customerEmail,
    required this.customerAddressText,
    this.customerCity,
    this.customerState,
    this.customerPincode,
    required this.paymentMethod,
    required this.paymentStatus,
    this.userType,

  });

  String get formattedDate =>
      '${placedOn.day}/${placedOn.month}/${placedOn.year}';

  String get formattedTime =>
      '${placedOn.hour}:${placedOn.minute.toString().padLeft(2, '0')}';

  int get totalItems =>
      products.fold(0, (sum, product) => sum + product.quantity);

  static String normalizePaymentMethod(String? method) {
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

  factory Order.fromJson(Map<String, dynamic> json) {
    DateTime placedOn;
    try {
      placedOn = DateTime.parse(json['date'].toString());
    } catch (_) {
      placedOn = DateTime.now();
    }

    OrderProcessStatus parseStatus(String? status) {
      if (status == null || status.trim().isEmpty) {
        return OrderProcessStatus.error;
      }

      final s = status
          .toLowerCase()
          .replaceAll('_', ' ')
          .trim();
      // ❌ CANCELLED (must be FIRST)
      if (s.contains('cancelled') || s.contains('canceled')) {
        return OrderProcessStatus.cancelled;
      }

      // 🚨 RTO STATES (MUST COME BEFORE delivered)
      if (s.contains('rto delivered')) {
        return OrderProcessStatus.rtoDelivered;
      }
      if (s.contains('rto')) {
        return OrderProcessStatus.rto;
      }

      // ❌ FAILED STATES
      if (s.contains('pickup failed')) return OrderProcessStatus.failed;
      if (s.contains('lost')) return OrderProcessStatus.failed;
      if (s.contains('damaged')) return OrderProcessStatus.failed;
      if (s.contains('destroyed')) return OrderProcessStatus.failed;
      if (s.contains('failed')) return OrderProcessStatus.failed;

      // ⏳ PENDING / IN-PROGRESS
      if (s == 'pending') return OrderProcessStatus.pending;
      if (s.contains('in transit')) return OrderProcessStatus.inTransit;
      if (s.contains('out for delivery')) return OrderProcessStatus.outForDelivery;

      // ✅ NORMAL FLOW
      if (s.contains('ordered')) return OrderProcessStatus.ordered;
      if (s.contains('awb generated')) return OrderProcessStatus.awbGenerated;
      if (s.contains('pickup')) return OrderProcessStatus.pickupRequested;
      if (s.contains('picked')) return OrderProcessStatus.pickedUp;
      if (s.contains('delivered')) return OrderProcessStatus.delivered;


      return OrderProcessStatus.error;
    }



    return Order(

      id: json['order_id']?.toString() ?? '',
      numericId: json['id']?.toString() ?? '', // Store numeric PK
      placedOn: placedOn,
      customerPhone: json['phone']?.toString() ?? '',
      customerEmail: json['email']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerAddressText: json['address']?.toString() ?? '',
      customerCity: json['city']?.toString(),
      customerState: json['state']?.toString(),
      customerPincode: json['pincode']?.toString(),
      orderStatus: parseStatus(json['status']),
      products: (json['items'] as List? ?? [])
          .map((e) => OrderedProduct.fromJson(e))
          .toList(),
      totalPrice: (json['amount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shipping_fee'] as num?)?.toDouble() ?? 0.0,
      stateGstAmount: (json['state_gst_amount'] as num?)?.toDouble() ?? 0.0,
      centralGstAmount: (json['central_gst_amount'] as num?)?.toDouble() ?? 0.0,
      stateGstPercent: (json['sgst_percentage'] as num?)?.toDouble(),
      centralGstPercent: (json['cgst_percentage'] as num?)?.toDouble(),
      paymentMethod: Order.normalizePaymentMethod(json['payment_method']?.toString()),
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      userType: json['customer_type']?.toString(),
    );
  }

}
