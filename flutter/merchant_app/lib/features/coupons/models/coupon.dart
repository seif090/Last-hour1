class Coupon {
  final String id;
  final String storeId;
  final String code;
  final String discountType;
  final double discountValue;
  final double? minOrderAmount;
  final double? maxDiscount;
  final int maxUses;
  final int currentUses;
  final bool isActive;
  final String? expiresAt;
  final String? startsAt;
  final String? description;
  final String createdAt;

  const Coupon({
    required this.id,
    required this.storeId,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscount,
    required this.maxUses,
    required this.currentUses,
    required this.isActive,
    this.expiresAt,
    this.startsAt,
    this.description,
    required this.createdAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String? ?? '',
      storeId: json['storeId'] as String? ?? json['store_id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      discountType: json['discountType'] as String? ?? json['discount_type'] as String? ?? 'percentage',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? (json['discount_value'] as num?)?.toDouble() ?? 0,
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? (json['min_order_amount'] as num?)?.toDouble(),
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble() ?? (json['max_discount'] as num?)?.toDouble(),
      maxUses: json['maxUses'] as int? ?? json['max_uses'] as int? ?? 100,
      currentUses: json['currentUses'] as int? ?? json['current_uses'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      expiresAt: json['expiresAt'] as String? ?? json['expires_at'] as String?,
      startsAt: json['startsAt'] as String? ?? json['starts_at'] as String?,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'storeId': storeId,
    'code': code,
    'discountType': discountType,
    'discountValue': discountValue,
    'minOrderAmount': minOrderAmount,
    'maxDiscount': maxDiscount,
    'maxUses': maxUses,
    'currentUses': currentUses,
    'isActive': isActive,
    'expiresAt': expiresAt,
    'startsAt': startsAt,
    'description': description,
    'createdAt': createdAt,
  };

  String get summary {
    if (discountType == 'percentage') return '$discountValue% off';
    return '$discountValue EGP off';
  }
}
