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

    final double compareAtPrice =
        (json['compare_at_price'] as num?)?.toDouble() ?? 0.0;
    final double basePrice = (isB2B
        ? (json['b2b_price'] as num?)?.toDouble() ?? 0.0
        : (json['b2c_price'] as num?)?.toDouble() ?? 0.0);

    // Parse Dates
    final String? startDateStr =
        isB2B ? json['b2b_offer_start_date'] : json['b2c_offer_start_date'];
    final String? endDateStr =
        isB2B ? json['b2b_offer_end_date'] : json['b2c_offer_end_date'];

    final DateTime? offerStartDate =
        startDateStr != null ? DateTime.tryParse(startDateStr) : null;
    final DateTime? offerEndDate =
        endDateStr != null ? DateTime.tryParse(endDateStr) : null;

    // Check if offer is active based on dates
    final DateTime now = DateTime.now();
    bool isOfferActiveByDate = true;
    if (offerStartDate != null && now.isBefore(offerStartDate))
      isOfferActiveByDate = false;
    if (offerEndDate != null && now.isAfter(offerEndDate))
      isOfferActiveByDate = false;

    // Check backend active flag (double precision in DB, check > 0)
    final double activeOfferFlag = isB2B
        ? (json['b2b_active_offer'] as num?)?.toDouble() ?? 0.0
        : (json['b2c_active_offer'] as num?)?.toDouble() ?? 0.0;

    final bool isActuallyActive = activeOfferFlag > 0 && isOfferActiveByDate;

    final double? offerPrice = isActuallyActive
        ? (isB2B
            ? (json['b2b_offer_price'] as num?)?.toDouble()
            : (json['b2c_offer_price'] as num?)?.toDouble())
        : null;

    final double? dbDiscountPercent = isB2B
        ? (json['b2b_discount'] as num?)?.toDouble()
        : (json['b2c_discount'] as num?)?.toDouble();

    // UI price mapping:
    // priceAfetDiscount is the current price to show (offer price or base price)
    // price is the strike price (compare_at_price if exists, else basePrice if there's an offer)
    double currentPrice = offerPrice ?? basePrice;
    double strikePrice = (compareAtPrice > 0)
        ? compareAtPrice
        : (offerPrice != null ? basePrice : basePrice);

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
      discountPercent: dbDiscountPercent,
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
