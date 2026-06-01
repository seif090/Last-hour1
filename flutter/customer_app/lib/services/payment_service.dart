import '../services/api_client.dart';

class PaymentService {
  final ApiClient _api;

  PaymentService(this._api);

  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    String? paymentMethodId,
  }) async {
    final response = await _api.post('/api/v1/payments/create-intent', body: {
      'amount': amount,
      'currency': currency,
      'payment_method_id': paymentMethodId,
    });

    if (!response.isSuccess || response.data == null) {
      throw Exception(response.error ?? 'Failed to create payment');
    }

    return response.data!;
  }

  Future<Map<String, dynamic>> confirmPayment({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    final response = await _api.post('/api/v1/payments/confirm', body: {
      'payment_intent_id': paymentIntentId,
      'payment_method_id': paymentMethodId,
    });

    if (!response.isSuccess || response.data == null) {
      throw Exception(response.error ?? 'Payment confirmation failed');
    }

    return response.data!;
  }
}
