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
    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      status: json['status'],
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      serviceFee: (json['service_fee'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      currency: json['currency'] ?? 'EGP',
      estimatedReadyAt: json['estimated_ready_at'] as String?,
      storeName: json['store']?['name'] ?? json['store_name'] ?? '',
      storeAddress: json['store']?['address_line1'] as String?,
      storeLat: (json['store']?['lat'] as num?)?.toDouble(),
      storeLng: (json['store']?['lng'] as num?)?.toDouble(),
      offerTitle: json['offer']?['title'] ?? json['offer_title'] ?? '',
      offerImageUrl: json['offer']?['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      statusHistory: (json['status_history'] as List?)
              ?.map((h) => StatusHistory.fromJson(h))
              .toList() ??
          [StatusHistory(status: json['status'], at: DateTime.parse(json['created_at']))],
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
      status: json['status'],
      at: DateTime.parse(json['at'] as String),
    );
  }

  @override
  List<Object?> get props => [status, at];
}
