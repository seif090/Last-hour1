import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/api_client.dart';
import '../../../injector.dart';

abstract class PaymentMethodsEvent {}

class LoadPaymentMethods extends PaymentMethodsEvent {}

class AddPaymentMethod extends PaymentMethodsEvent {
  final Map<String, dynamic> data;
  AddPaymentMethod(this.data);
}

class DeletePaymentMethod extends PaymentMethodsEvent {
  final String id;
  DeletePaymentMethod(this.id);
}

class SetDefaultPaymentMethod extends PaymentMethodsEvent {
  final String id;
  SetDefaultPaymentMethod(this.id);
}

abstract class PaymentMethodsState {}

class PaymentMethodsInitial extends PaymentMethodsState {}

class PaymentMethodsLoading extends PaymentMethodsState {}

class PaymentMethodsLoaded extends PaymentMethodsState {
  final List<Map<String, dynamic>> methods;
  PaymentMethodsLoaded(this.methods);
}

class PaymentMethodsError extends PaymentMethodsState {
  final String message;
  PaymentMethodsError(this.message);
}

class PaymentMethodsBloc extends Bloc<PaymentMethodsEvent, PaymentMethodsState> {
  final ApiClient _api;

  PaymentMethodsBloc({required ApiClient api})
      : _api = api,
        super(PaymentMethodsInitial()) {
    on<LoadPaymentMethods>(_onLoad);
    on<AddPaymentMethod>(_onAdd);
    on<DeletePaymentMethod>(_onDelete);
    on<SetDefaultPaymentMethod>(_onSetDefault);
  }

  void _onLoad(LoadPaymentMethods event, Emitter<PaymentMethodsState> emit) async {
    emit(PaymentMethodsLoading());
    try {
      final resp = await _api.get('/api/v1/payment-methods');
      if (resp.isSuccess && resp.data != null) {
        final list = (resp.data!['data'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        emit(PaymentMethodsLoaded(list));
      } else {
        emit(PaymentMethodsError(resp.error ?? 'Failed to load'));
      }
    } catch (e) {
      emit(PaymentMethodsError(e.toString()));
    }
  }

  void _onAdd(AddPaymentMethod event, Emitter<PaymentMethodsState> emit) async {
    try {
      await _api.post('/api/v1/payment-methods', body: event.data);
      add(LoadPaymentMethods());
    } catch (e) {
      emit(PaymentMethodsError(e.toString()));
    }
  }

  void _onDelete(DeletePaymentMethod event, Emitter<PaymentMethodsState> emit) async {
    try {
      await _api.delete('/api/v1/payment-methods/${event.id}');
      add(LoadPaymentMethods());
    } catch (e) {
      emit(PaymentMethodsError(e.toString()));
    }
  }

  void _onSetDefault(SetDefaultPaymentMethod event, Emitter<PaymentMethodsState> emit) async {
    try {
      await _api.patch('/api/v1/payment-methods/${event.id}', body: {'isDefault': true});
      add(LoadPaymentMethods());
    } catch (e) {
      emit(PaymentMethodsError(e.toString()));
    }
  }
}
