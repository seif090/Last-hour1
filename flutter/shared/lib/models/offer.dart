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
    return Offer(
      id: json['id'] ?? json['offer_id'],
      title: json['title'],
      discountedPrice: (json['discounted_price'] as num).toDouble(),
      originalPrice: (json['original_price'] as num).toDouble(),
      stockRemaining: json['stock_remaining'] as int,
      stockInitial: json['stock_initial'] as int,
      endTime: DateTime.parse(json['end_time'] as String),
      maxPerCustomer: json['max_per_customer'] as int? ?? 5,
      imageUrl: json['image_url'] as String?,
      storeId: json['store_id'] ?? json['store']['id'],
      storeName: json['store_name'] ?? json['store']['name'],
      storeSlug: json['store_slug'] ?? json['store']['slug'] ?? '',
      cuisineType: json['cuisine_type'] as String?,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      distanceM: (json['distance_m'] as num?)?.toDouble() ?? 0,
      productName: json['product_name'] ?? json['product']['name'],
      category: json['category'] ?? json['product']['category'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, stockRemaining];
}
