import 'dart:convert';

class ProductModel {
  final String id;
  final String title;
  final String category;
  final String? description;
  final String brandName;

  final String? hsnCode;
  final double weightKg;
  final double lengthCm;
  final double breadthCm;
  final double heightCm;
  final double stateGstPercent;
  final double centralGstPercent;
  final List<String> colors;

  /// Images
  final String image; // main image (thumbnail)
  final List<String> images; // gallery images

  /// Pricing
  final double compareAtPrice;
  final double price; // Strike price (usually MRP or base price if no MRP)
  final double?
      priceAfetDiscount; // Actual price to pay (offer price or base price)
  final double? discountPercent;

  /// Offer Dates
  final DateTime? offerStartDate;
  final DateTime? offerEndDate;

  /// Stock & status
  final int stock;
  final bool isAvailable;

  /// Reviews
  final double rating;
  final int reviews;

  /// Meta
  final dynamic info;
  final String? returnPolicy;

  ProductModel({
    required this.id,
    required this.title,
    required this.category,
    required this.brandName,
    required this.image,
    required this.images,
    required this.compareAtPrice,
    required this.price,
    required this.stock,
    required this.isAvailable,
    required this.weightKg,
    required this.lengthCm,
    required this.breadthCm,
    required this.heightCm,
    required this.stateGstPercent,
    required this.centralGstPercent,
    this.hsnCode,
    this.description,
    this.priceAfetDiscount,
    this.discountPercent,
    this.offerStartDate,
    this.offerEndDate,
    this.rating = 0.0,
    this.reviews = 0,
    this.info,
    required this.colors,
    this.returnPolicy,
  });

  // ========================= FROM JSON =========================
  factory ProductModel.fromJson(Map<String, dynamic> json,
      {String userType = 'b2c'}) {
    // ---------- Parse images safely ----------
    List<String> parseImages(dynamic data) {
      if (data == null) return [];
      if (data is List) return data.map((e) => e.toString()).toList();
      if (data is String) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
          return [data];
        } catch (_) {
          return [data];
        }
      }
      return [];
    }

    // ---------- Parse Util ----------
    List<String> parseList(dynamic data) {
      if (data == null) return [];
      if (data is List) return data.map((e) => e.toString()).toList();
      if (data is String) {
        if (data.trim().isEmpty) return [];
        try {
          final decoded = jsonDecode(data);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
          return [data];
        } catch (_) {
          // Fallback cleanup for strings like "[Color1, Color2]" or "Color1, Color2"
          String clean = data.replaceAll('[', '').replaceAll(']', '');
          if (clean.trim().isEmpty) return [];
          return clean
              .split(',')
              .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ""))
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
      return [];
    }

    final List<String> images = parseImages(json['images'] ?? json['image']);
    final String mainImage =
        images.isNotEmpty ? images.first : json['image']?.toString() ?? '';

    // ---------- Pricing & Offers ----------
    final bool isB2B = userType.toLowerCase() == 'b2b';

    // Use backend's current_price directly if available (already calculated with date validation)
    final double? backendCurrentPrice = (json['current_price'] as num?)?.toDouble();

    final double compareAtPrice =
        (json['compare_at_price'] as num?)?.toDouble() ?? 0.0;
    final double basePrice = (isB2B
        ? (json['b2b_price'] as num?)?.toDouble() ?? 0.0
        : (json['b2c_price'] as num?)?.toDouble() ?? 0.0);

    // Parse Dates for UI display only
    final String? startDateStr =
        isB2B ? json['b2b_offer_start_date'] : json['b2c_offer_start_date'];
    final String? endDateStr =
        isB2B ? json['b2b_offer_end_date'] : json['b2c_offer_end_date'];

    // Helper function to parse backend date format
    DateTime? _parseBackendDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        // Handle "2025-12-15 15:49:00" format
        return DateTime.parse(dateStr.replaceAll(' ', 'T'));
      } catch (e) {
        return null;
      }
    }

    final DateTime? offerStartDate = _parseBackendDate(startDateStr);
    final DateTime? offerEndDate = _parseBackendDate(endDateStr);

    // Check if time-limited offer is active based on dates
    // Backend provides b2c_active_offer / b2b_active_offer as flag
    final DateTime now = DateTime.now();
    bool isTimeLimitedOfferActive = false;

    // Get active offer flag from backend
    final double activeOfferFlag = isB2B
        ? (json['b2b_active_offer'] as num?)?.toDouble() ?? 0.0
        : (json['b2c_active_offer'] as num?)?.toDouble() ?? 0.0;

    // Check if time-limited offer dates are valid (not expired, not future)
    // If only end date exists and hasn't expired, offer is active
    // If both dates exist, offer must be within the date range
    if (activeOfferFlag > 0 && offerEndDate != null) {
      final endOfDay = DateTime(offerEndDate.year, offerEndDate.month, offerEndDate.day, 23, 59, 59);
      if (now.isBefore(endOfDay)) {
        // End date not expired, check start date
        if (offerStartDate == null) {
          // No start date means offer is already active
          isTimeLimitedOfferActive = true;
        } else if (now.isAfter(offerStartDate) || now.isAtSameMomentAs(offerStartDate)) {
          // Start date has passed
          isTimeLimitedOfferActive = true;
        }
        // If now is before start date, offer hasn't started yet (isTimeLimitedOfferActive = false)
      }
      // If end date is expired, offer is not active
    }
    // If no end date but has start date and start date has passed, offer is active
    else if (activeOfferFlag > 0 && offerStartDate != null && (now.isAfter(offerStartDate) || now.isAtSameMomentAs(offerStartDate))) {
      isTimeLimitedOfferActive = true;
    }

    // Calculate current price: Time-limited offer > Regular price
    double currentPrice;

    // Priority 1: If backend sends current_price (already calculated with date validation), use it
    if (backendCurrentPrice != null && backendCurrentPrice > 0) {
      currentPrice = backendCurrentPrice;
    }
    // Priority 2: If time-limited offer is active (based on flag and dates), use offer price
    else if (isTimeLimitedOfferActive) {
      // Use offer price from backend
      final double? offerPrice = isB2B
          ? (json['b2b_offer_price'] as num?)?.toDouble()
          : (json['b2c_offer_price'] as num?)?.toDouble();

      if (offerPrice != null && offerPrice > 0) {
        currentPrice = offerPrice;
      } else {
        // Fallback: Use base price if no offer price
        currentPrice = basePrice;
      }
    }
    // Priority 3: Use regular B2B/B2C price (permanent discount already applied)
    else {
      currentPrice = basePrice;
    }

    // Strike price = compare_at_price if exists, else base price
    double strikePrice = (compareAtPrice > 0) ? compareAtPrice : basePrice;

    // Calculate discount percentage
    // If time-limited offer is active, show that discount, otherwise show regular discount
    double? discountPercent;
    if (isTimeLimitedOfferActive && compareAtPrice > 0 && currentPrice < compareAtPrice) {
      // Calculate time-limited offer discount
      discountPercent = ((compareAtPrice - currentPrice) / compareAtPrice) * 100;
    } else if (currentPrice < compareAtPrice && compareAtPrice > 0) {
      // Calculate discount from regular pricing
      discountPercent = ((compareAtPrice - currentPrice) / compareAtPrice) * 100;
    } else {
      // Fallback to stored discount value from backend
      discountPercent = isB2B
          ? (json['b2b_discount'] as num?)?.toDouble()
          : (json['b2c_discount'] as num?)?.toDouble();
    }

    dynamic parsedInfo;
    if (json['info'] != null) {
      try {
        parsedInfo = jsonDecode(json['info']);
      } catch (_) {
        parsedInfo = json['info'];
      }
    }

    return ProductModel(
      id: json['id'].toString(),
      title: json['name']?.toString() ?? '',
      hsnCode: json['hsn']?.toString(),
      brandName: json['brand_name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString(),
      weightKg: (json['weight'] ?? 0).toDouble(),
      lengthCm: (json['length'] ?? 0).toDouble(),
      breadthCm: (json['breadth'] ?? 0).toDouble(),
      heightCm: (json['height'] ?? 0).toDouble(),
      stateGstPercent: (json['sgst'] ?? 0).toDouble(),
      centralGstPercent: (json['cgst'] ?? 0).toDouble(),
      colors: parseList(json['colors']),
      image: mainImage,
      images: images,
      compareAtPrice: compareAtPrice,
      price: strikePrice,
      priceAfetDiscount: currentPrice,
      discountPercent: discountPercent,
      offerStartDate: offerStartDate,
      offerEndDate: offerEndDate,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isAvailable:
          (json['status'] == 'Published' || json['status'] == 'Active') &&
              ((json['stock'] as num?)?.toInt() ?? 0) > 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      info: parsedInfo,
      returnPolicy: json['return_policy']?.toString(),
    );
  }

  // ========================= TO JSON =========================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': title,
      'brand_name': brandName,
      'category': category,
      'description': description,
      'image': image,
      'images': images,
      'compare_at_price': compareAtPrice,
      'price': price,
      'price_after_discount': priceAfetDiscount,
      'discount_percentage': discountPercent,
      'stock': stock,
      'status': isAvailable ? 'Active' : 'Archived',
      'rating': rating,
      'reviews': reviews,
      'info': info,
      'return_policy': returnPolicy,
    };
  }

  // ========================= UI HELPERS =========================
  bool get hasDiscount =>
      priceAfetDiscount != null && priceAfetDiscount! < price;
  double get finalPrice => priceAfetDiscount ?? price;

  int? get discountPercentUI {
    if (discountPercent != null && discountPercent! > 0) {
      return discountPercent!.round();
    }
    if (price > 0 && priceAfetDiscount != null && priceAfetDiscount! < price) {
      return (((price - priceAfetDiscount!) / price) * 100).round();
    }
    return null;
  }

  // ========================= OVERRIDES =========================
  @override
  String toString() =>
      'ProductModel(id: $id, title: $title, price: $finalPrice)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProductModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
