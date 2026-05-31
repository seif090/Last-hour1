import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'api_client.dart';

class PaymentService {
  final ApiClient _api;

  PaymentService(this._api);

  Future<String> initializePayment(double amount, String currency) async {
    try {
      final response = await _api.post('/api/v1/payments/create-intent', body: {
        'amount': (amount * 100).toInt(),
        'currency': currency,
      });

      if (!response.isSuccess || response.data == null) {
        throw Exception('Failed to create payment intent');
      }

      return response.data!['client_secret'] as String;
    } catch (e) {
      debugPrint('Payment intent creation failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String currency,
    required String offerId,
    required int quantity,
    String? notes,
  }) async {
    try {
      // 1. Create payment intent via backend
      final clientSecret = await initializePayment(amount, currency);

      // 2. Confirm payment with Stripe SDK
      final paymentIntentParams = PaymentIntentParams(
        paymentIntentData: {
          'amount': (amount * 100).toInt(),
          'currency': currency.toLowerCase(),
          'client_secret': clientSecret,
        },
      );

      final paymentResult = await Stripe.instance.confirmPayment(
        clientSecret,
        PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(),
          ),
        ),
      );

      if (paymentResult.status != PaymentIntentsStatus.Succeeded) {
        throw Exception('Payment failed: ${paymentResult.status}');
      }

      // 3. Place order
      final orderResponse = await _api.post('/api/v1/orders', body: {
        'offer_id': offerId,
        'quantity': quantity,
        'payment': {
          'provider': 'stripe',
          'payment_method_id': paymentResult.paymentIntentId,
        },
        if (notes != null) 'notes': notes,
      });

      if (!orderResponse.isSuccess) {
        throw Exception(orderResponse.error ?? 'Order placement failed');
      }

      return orderResponse.data! as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Payment flow failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> setupApplePay() async {
    await Stripe.instance.setApplePay();
    return {};
  }

  Future<Map<String, dynamic>> setupGooglePay() async {
    await Stripe.instance.setGooglePay();
    return {};
  }
}
