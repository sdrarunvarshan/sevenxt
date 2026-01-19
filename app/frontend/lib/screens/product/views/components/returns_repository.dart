import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';import 'package:sevenext/models/order_model.dart';import 'package:sevenext/models/return_model.dart';import 'package:sevenext/route/api_service.dart';

class ReturnsRepository {

  /// 🔹 Submit return request → BACKEND
  static Future<void> submitReturnRequest({
    required Order order,
    required OrderedProduct product,
    required String reason,
    required String details,
    required List<XFile> images,
    required ReturnType type,
    required int quantity,
  }) async {
    try {
      await ApiService.submitReturnRequestMultipart(
        order: order,
        product: product,
        reason: reason,
        details: details,
        images: images,
        type: type,
        quantity: quantity,
      );
    } catch (e) {
      debugPrint('Error submitting return request: $e');
      rethrow;
    }
  }

  /// 🔹 Get all returns + exchanges for a specific order
  static Future<List<ReturnRequest>> getReturnsForOrder(String orderId) async {
    try {
      debugPrint("📡 Fetching returns/exchanges for order: $orderId");

      // 1️⃣ Fetch refunds
      final refundsResponse = await ApiService.getRefundsForOrder(orderId);
      List<dynamic> refundsData = refundsResponse['returns'] ?? refundsResponse['refunds'] ?? [];
      debugPrint("✅ Refunds found: ${refundsData.length}");

      // 2️⃣ Fetch exchanges
      final exchangesResponse = await ApiService.getExchangesForOrder(orderId);
      List<dynamic> exchangesData = exchangesResponse['exchanges'] ?? [];
      debugPrint("✅ Exchanges found: ${exchangesData.length}");

      // 3️⃣ Map refunds
      final refunds = refundsData.map<ReturnRequest>((json) {
        try {
          return ReturnRequest.fromJson({
            ...json,
            'type': 'refund',
          });
        } catch (e) {
          debugPrint("❌ Error parsing refund JSON: $e\nData: $json");
          rethrow;
        }
      }).toList();

      // 4️⃣ Map exchanges
      final exchanges = exchangesData.map<ReturnRequest>((json) {
        try {
          return ReturnRequest.fromJson({
            ...json,
            'type': 'exchange',
            'payment_method': json['payment_method'] ?? '',
            'amount': json['amount'] ?? 0.0,
          });
        } catch (e) {
          debugPrint("❌ Error parsing exchange JSON: $e\nData: $json");
          rethrow;
        }
      }).toList();

      final allReturns = [...refunds, ...exchanges];
      debugPrint("📦 Total return requests mapped: ${allReturns.length}");
      return allReturns;
    } catch (e) {
      debugPrint('❌ Error fetching returns for order: $e');
      rethrow;
    }
  }

  /// 🔹 Get user's refunds
  static Future<List<ReturnRequest>> getUserRefunds() async {
    try {
      final response = await ApiService.getUserRefunds();
      List<dynamic> refundsData = response['refunds'] ?? [];

      return refundsData
          .map<ReturnRequest>((json) => ReturnRequest.fromJson({
        ...json,
        'type': 'refund',
      }))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user refunds: $e');
      rethrow;
    }
  }

  /// 🔹 Get user's exchanges
  static Future<List<ReturnRequest>> getUserExchanges() async {
    try {
      final response = await ApiService.getUserExchanges();
      List<dynamic> exchangesData = response['exchanges'] ?? [];

      return exchangesData
          .map<ReturnRequest>((json) => ReturnRequest.fromJson({
        ...json,
        'type': 'exchange',
        'payment_method': '',
        'amount': 0.0,
      }))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user exchanges: $e');
      rethrow;
    }
  }

  /// 🔹 Get ALL user returns
  static Future<List<ReturnRequest>> getAllUserReturns() async {
    try {
      final refunds = await getUserRefunds();
      final exchanges = await getUserExchanges();

      return [...refunds, ...exchanges];
    } catch (e) {
      debugPrint('Error fetching all user returns: $e');
      rethrow;
    }
  }
}
