class ApiConstants {
  static const String baseUrl = 'http://localhost:3000';
  static const String apiPrefix = '/api/v1';
  static const String wsUrl = 'ws://localhost:3000/ws';
  static const String wsPath = '/ws';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Auth
  static const String login = '$apiPrefix/auth/login';
  static const String register = '$apiPrefix/auth/register';

  // Offers
  static const String nearbyOffers = '$apiPrefix/offers/nearby';
  static String offerDetail(String id) => '$apiPrefix/offers/$id';

  // Orders
  static const String orders = '$apiPrefix/orders';
  static String orderDetail(String id) => '$apiPrefix/orders/$id';
  static String trackOrder(String id) => '$apiPrefix/orders/$id/track';

  // Merchant
  static const String merchantDashboard = '$apiPrefix/merchant/dashboard';
  static const String merchantSales = '$apiPrefix/merchant/sales/today';
  static const String merchantOffers = '$apiPrefix/merchant/offers';
  static String merchantOfferStock(String id) => '$apiPrefix/merchant/offers/$id/stock';
  static const String merchantOrders = '$apiPrefix/merchant/orders';
  static String merchantOrderStatus(String id) => '$apiPrefix/merchant/orders/$id/status';
  static const String merchantProducts = '$apiPrefix/merchant/products';

  // Reviews
  static const String reviews = '$apiPrefix/reviews';
  static String storeReviews(String id) => '$apiPrefix/reviews/store/$id';

  // Admin
  static const String adminStats = '$apiPrefix/admin/stats';
  static const String adminMerchants = '$apiPrefix/admin/merchants';
  static String adminMerchantVerify(String id) => '$apiPrefix/admin/merchants/$id/verify';
  static const String adminSystemHealth = '$apiPrefix/admin/system/health';

  // Payments
  static const String createPaymentIntent = '$apiPrefix/payments/create-intent';

  // Health
  static const String health = '$apiPrefix/health';
}
