import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? district;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.district,
    this.postalCode,
    this.latitude,
    this.longitude,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      label: json['label'] as String? ?? 'Home',
      addressLine1: json['addressLine1'] as String,
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String,
      district: json['district'] as String?,
      postalCode: json['postalCode'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'city': city,
    'district': district,
    'postalCode': postalCode,
    'latitude': latitude,
    'longitude': longitude,
    'isDefault': isDefault,
  };

  @override
  List<Object?> get props => [id];
}
