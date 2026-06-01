import 'package:equatable/equatable.dart';

class Order extends Equatable {
  final String id;
  final String orderNumber;
  final String status;
  final int quantity;
  final double subtotal;
  final double serviceFee;
  final double totalAmount;
  final String currency;
  final String? estimatedReadyAt;
  final String storeName;
  final String? storeAddress;
  final double? storeLat;
  final double? storeLng;
  final String offerTitle;
  final String? offerImageUrl;
  final DateTime createdAt;
  final List<StatusHistory> statusHistory;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.quantity,
    required this.subtotal,
    required this.serviceFee,
    required this.totalAmount,
    required this.currency,
    this.estimatedReadyAt,
    required this.storeName,
    this.storeAddress,
    this.storeLat,
    this.storeLng,
    required this.offerTitle,
    this.offerImageUrl,
    required this.createdAt,
    this.statusHistory = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final store = json['store'] as Map<String, dynamic>?;
    final offer = json['offer'] as Map<String, dynamic>?;
    final now = DateTime.now();
    return Order(
      id: json['id'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      quantity: json['quantity'] as int? ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'EGP',
      estimatedReadyAt: json['estimated_ready_at'] as String?,
      storeName: store?['name'] as String? ?? json['store_name'] as String? ?? '',
      storeAddress: store?['address_line1'] as String? ?? json['store_address'] as String?,
      storeLat: (store?['lat'] as num?)?.toDouble() ?? (json['store_lat'] as num?)?.toDouble(),
      storeLng: (store?['lng'] as num?)?.toDouble() ?? (json['store_lng'] as num?)?.toDouble(),
      offerTitle: offer?['title'] as String? ?? json['offer_title'] as String? ?? '',
      offerImageUrl: offer?['image_url'] as String? ?? json['offer_image_url'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : now,
      statusHistory: (json['status_history'] as List?)
              ?.map((h) => StatusHistory.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [StatusHistory(status: json['status'] as String? ?? 'pending', at: now)],
    );
  }

  @override
  List<Object?> get props => [id, status];
}

class StatusHistory extends Equatable {
  final String status;
  final DateTime at;

  const StatusHistory({required this.status, required this.at});

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    return StatusHistory(
      status: json['status'] as String? ?? 'pending',
      at: json['at'] != null ? DateTime.parse(json['at'] as String) : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [status, at];
}
