import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

enum ReturnType {
  refund,    // Money back
  exchange,  // Product replacement
}

class ReturnRequest {
  final String id;
  final int quantity;
  final String orderId;
  final String reason;
  final String? details;
  final int orderItemId;
  final List<String> imagePaths;
  final DateTime requestedDate;
  final ReturnStatus status;
  final String paymentMethod;
  final double refundAmount;
  final String currency;
  final ReturnType type; // refund or exchange

  ReturnRequest({
    required this.id,
    required this.quantity,
    required this.orderId,
    required this.reason,
    this.details,
    required this.imagePaths,
    required this.requestedDate,
    required this.orderItemId,
    required this.status,
    required this.paymentMethod,
    required this.refundAmount,
    this.currency = 'INR',
    this.type = ReturnType.refund,
  });

  /// 🔁 FROM BACKEND JSON
  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    return ReturnRequest(
      id: (json['return_id'] ?? json['id'] ?? '').toString(),
      quantity: (json['quantity'] ?? 1).toInt(),
      orderId: (json['order_id'] ?? '').toString(),
      orderItemId: json['order_item_id'] != null
          ? (json['order_item_id'] is int
              ? json['order_item_id']
              : int.tryParse(json['order_item_id'].toString()) ?? 0)
          : 0,
      reason: json['reason']?.toString() ?? '',
      details: json['details']?.toString(),
      imagePaths: List<String>.from(json['images'] ?? []),
      requestedDate: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: ReturnStatusExtension.fromString(json['status']?.toString() ?? 'pending'),
      paymentMethod: json['payment_method']?.toString() ?? '',
      refundAmount: ((json['amount'] ?? json['refund_amount'] ?? 0.0) as num).toDouble(),
      currency: json['currency']?.toString() ?? 'INR',
      type: json['type']?.toString().toLowerCase() == 'exchange'
          ? ReturnType.exchange
          : ReturnType.refund,
    );
  }

  /// 🔁 TO BACKEND JSON (for submit)
  Map<String, dynamic> toJson() {
    final json = {
      "order_item_id": orderItemId,
      "reason": reason,
      "description": details,
      "proof_image_path": imagePaths,
    };

    if (type == ReturnType.refund) {
      json["payment_method"] = paymentMethod;
      json["amount"] = refundAmount;
    }

    return json;
  }

  String get formattedDate =>
      DateFormat('dd MMM yyyy').format(requestedDate);
}

enum ReturnStatus {
  pending,
  approved,
  rejected,
  }

extension ReturnStatusExtension on ReturnStatus {
  static ReturnStatus fromString(String value) {
    final normalizedValue = value.toLowerCase();
    return ReturnStatus.values.firstWhere(
          (e) => e.name == normalizedValue,
      orElse: () => ReturnStatus.pending,
    );
  }

  Color get color {
    switch (this) {
      case ReturnStatus.approved:
        return Colors.green;
      case ReturnStatus.rejected:
        return Colors.red;
       default:
        return Colors.orange;
    }
  }

  String get label => name[0].toUpperCase() + name.substring(1);
}
