import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../injector.dart';
import '../../../services/api_client.dart';
import '../models/coupon.dart';

abstract class CouponsEvent {}

class LoadCoupons extends CouponsEvent {
  final String storeId;
  LoadCoupons(this.storeId);
}

class CreateCoupon extends CouponsEvent {
  final String storeId;
  final String code;
  final String discountType;
  final double discountValue;
  final double? minOrderAmount;
  final double? maxDiscount;
  final int? maxUses;
  final String? expiresAt;
  final String? description;
  CreateCoupon({
    required this.storeId, required this.code, required this.discountType,
    required this.discountValue, this.minOrderAmount, this.maxDiscount,
    this.maxUses, this.expiresAt, this.description,
  });
}

class ToggleCoupon extends CouponsEvent {
  final String couponId;
  ToggleCoupon(this.couponId);
}

abstract class CouponsState {}

class CouponsInitial extends CouponsState {}

class CouponsLoading extends CouponsState {}

class CouponsLoaded extends CouponsState {
  final List<Coupon> coupons;
  final String? selectedStoreId;
  CouponsLoaded({required this.coupons, this.selectedStoreId});
}

class CouponsError extends CouponsState {
  final String message;
  CouponsError(this.message);
}

class CouponsBloc extends Bloc<CouponsEvent, CouponsState> {
  final ApiClient _api;

  CouponsBloc({required ApiClient api})
      : _api = api,
        super(CouponsInitial()) {
    on<LoadCoupons>(_onLoad);
    on<CreateCoupon>(_onCreate);
    on<ToggleCoupon>(_onToggle);
  }

  Future<void> _onLoad(LoadCoupons event, Emitter<CouponsState> emit) async {
    emit(CouponsLoading());
    try {
      final response = await _api.get('/api/v1/merchant/coupons/${event.storeId}');
      if (response.isSuccess && response.data != null) {
        final list = (response.data!['data'] as List? ?? response.data!['coupons'] as List? ?? [])
            .map((j) => Coupon.fromJson(j as Map<String, dynamic>))
            .toList();
        emit(CouponsLoaded(coupons: list, selectedStoreId: event.storeId));
      } else {
        emit(CouponsError(response.error ?? 'Failed to load coupons'));
      }
    } catch (e) {
      emit(CouponsError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateCoupon event, Emitter<CouponsState> emit) async {
    try {
      final body = <String, dynamic>{
        'storeId': event.storeId,
        'code': event.code,
        'discountType': event.discountType,
        'discountValue': event.discountValue,
        if (event.minOrderAmount != null) 'minOrderAmount': event.minOrderAmount,
        if (event.maxDiscount != null) 'maxDiscount': event.maxDiscount,
        if (event.maxUses != null) 'maxUses': event.maxUses,
        if (event.expiresAt != null) 'expiresAt': event.expiresAt,
        if (event.description != null) 'description': event.description,
      };
      final response = await _api.post('/api/v1/merchant/coupons', body: body);
      if (response.isSuccess) {
        add(LoadCoupons(event.storeId));
      } else {
        emit(CouponsError(response.error ?? 'Failed to create coupon'));
      }
    } catch (e) {
      emit(CouponsError(e.toString()));
    }
  }

  Future<void> _onToggle(ToggleCoupon event, Emitter<CouponsState> emit) async {
    try {
      await _api.patch('/api/v1/merchant/coupons/${event.couponId}/toggle');
      if (state is CouponsLoaded) {
        add(LoadCoupons((state as CouponsLoaded).selectedStoreId!));
      }
    } catch (e) {
      emit(CouponsError(e.toString()));
    }
  }
}
