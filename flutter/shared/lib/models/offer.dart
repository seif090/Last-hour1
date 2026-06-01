import 'package:equatable/equatable.dart';

class Offer extends Equatable {
  final String id;
  final String title;
  final double discountedPrice;
  final double originalPrice;
  final int stockRemaining;
  final int stockInitial;
  final DateTime endTime;
  final int maxPerCustomer;
  final String? imageUrl;
  final String storeId;
  final String storeName;
  final String storeSlug;
  final String? cuisineType;
  final double ratingAvg;
  final int ratingCount;
  final double distanceM;
  final String productName;
  final String category;
  final double lat;
  final double lng;

  const Offer({
    required this.id,
    required this.title,
    required this.discountedPrice,
    required this.originalPrice,
    required this.stockRemaining,
    required this.stockInitial,
    required this.endTime,
    required this.maxPerCustomer,
    this.imageUrl,
    required this.storeId,
    required this.storeName,
    required this.storeSlug,
    this.cuisineType,
    required this.ratingAvg,
    required this.ratingCount,
    required this.distanceM,
    required this.productName,
    required this.category,
    required this.lat,
    required this.lng,
  });

  double get discountPercent => ((originalPrice - discountedPrice) / originalPrice * 100);
  bool get isLowStock => stockRemaining <= stockInitial * 0.1;
  bool get isSoldOut => stockRemaining == 0;
  int get expiresInSeconds => endTime.difference(DateTime.now()).inSeconds;

  factory Offer.fromJson(Map<String, dynamic> json) {
    final store = json['store'] as Map<String, dynamic>?;
    final product = json['product'] as Map<String, dynamic>?;
    return Offer(
      id: json['id'] as String? ?? json['offer_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      discountedPrice: (json['discounted_price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
      stockRemaining: json['stock_remaining'] as int? ?? 0,
      stockInitial: json['stock_initial'] as int? ?? 0,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : DateTime.now(),
      maxPerCustomer: json['max_per_customer'] as int? ?? 5,
      imageUrl: json['image_url'] as String?,
      storeId: json['store_id'] as String? ?? store?['id'] as String? ?? '',
      storeName: json['store_name'] as String? ?? store?['name'] as String? ?? '',
      storeSlug: json['store_slug'] as String? ?? store?['slug'] as String? ?? '',
      cuisineType: json['cuisine_type'] as String?,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      distanceM: (json['distance_m'] as num?)?.toDouble() ?? 0,
      productName: json['product_name'] as String? ?? product?['name'] as String? ?? '',
      category: json['category'] as String? ?? product?['category'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [id, stockRemaining];
}
