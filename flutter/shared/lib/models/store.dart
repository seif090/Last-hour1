import 'package:equatable/equatable.dart';

class Store extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? cuisineType;
  final double ratingAvg;
  final int ratingCount;
  final double? distanceM;
  final String city;
  final String? district;
  final String addressLine1;
  final double lat;
  final double lng;
  final String? coverImageUrl;
  final String? logoUrl;
  final String? opensAt;
  final String? closesAt;

  const Store({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.cuisineType,
    required this.ratingAvg,
    required this.ratingCount,
    this.distanceM,
    required this.city,
    this.district,
    required this.addressLine1,
    required this.lat,
    required this.lng,
    this.coverImageUrl,
    this.logoUrl,
    this.opensAt,
    this.closesAt,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'] as String?,
      cuisineType: json['cuisine_type'] as String?,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      distanceM: (json['distance_m'] as num?)?.toDouble(),
      city: json['city'] ?? '',
      district: json['district'] as String?,
      addressLine1: json['address_line1'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? (json['location']?['coordinates']?[1] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? (json['location']?['coordinates']?[0] as num?)?.toDouble() ?? 0,
      coverImageUrl: json['cover_image_url'] as String?,
      logoUrl: json['logo_url'] as String?,
      opensAt: json['opens_at'] as String?,
      closesAt: json['closes_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name];
}
