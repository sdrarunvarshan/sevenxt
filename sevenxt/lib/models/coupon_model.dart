class Coupon {
  final String code;
  final String discountType;
  final double discountValue;
  final double minOrderValue;
  final DateTime? expiresAt;

  Coupon({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    this.expiresAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      code: json['code'],
      discountType: json['discount_type'],
      discountValue: (json['discount_value'] as num).toDouble(),
      minOrderValue: (json['min_order_value'] as num).toDouble(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
    );
  }
}
