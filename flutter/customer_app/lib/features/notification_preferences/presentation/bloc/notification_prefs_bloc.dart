import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/api_client.dart';
import '../../../../injector.dart';

abstract class NotificationPrefsEvent {}

class LoadNotificationPrefs extends NotificationPrefsEvent {}

class TogglePushEnabled extends NotificationPrefsEvent {}

class ToggleOrderConfirmed extends NotificationPrefsEvent {}

class ToggleOrderReady extends NotificationPrefsEvent {}

class ToggleNearbyOffers extends NotificationPrefsEvent {}

class TogglePromotions extends NotificationPrefsEvent {}

abstract class NotificationPrefsState {}

class NotificationPrefsInitial extends NotificationPrefsState {}

class NotificationPrefsLoading extends NotificationPrefsState {}

class NotificationPrefsLoaded extends NotificationPrefsState {
  final Map<String, dynamic> prefs;
  NotificationPrefsLoaded(this.prefs);
}

class NotificationPrefsError extends NotificationPrefsState {
  final String message;
  NotificationPrefsError(this.message);
}

class NotificationPrefsBloc extends Bloc<NotificationPrefsEvent, NotificationPrefsState> {
  final ApiClient _api;

  NotificationPrefsBloc({required ApiClient api})
      : _api = api,
        super(NotificationPrefsInitial()) {
    on<LoadNotificationPrefs>(_onLoad);
    on<TogglePushEnabled>(_onToggle('pushEnabled'));
    on<ToggleOrderConfirmed>(_onToggle('orderConfirmed'));
    on<ToggleOrderReady>(_onToggle('orderReady'));
    on<ToggleNearbyOffers>(_onToggle('nearbyOffers'));
    on<TogglePromotions>(_onToggle('promotions'));
  }

  void _onLoad(LoadNotificationPrefs event, Emitter<NotificationPrefsState> emit) async {
    emit(NotificationPrefsLoading());
    try {
      final resp = await _api.get('/api/v1/notification-preferences');
      if (resp.isSuccess && resp.data != null) {
        emit(NotificationPrefsLoaded(resp.data!));
      } else {
        emit(NotificationPrefsError(resp.error ?? 'Failed to load'));
      }
    } catch (e) {
      emit(NotificationPrefsError(e.toString()));
    }
  }

  Function(NotificationPrefsEvent, Emitter<NotificationPrefsState>) _onToggle(String field) {
    return (event, emit) async {
      if (state is NotificationPrefsLoaded) {
        final current = (state as NotificationPrefsLoaded).prefs;
        final newVal = !(current[field] as bool? ?? true);
        try {
          await _api.patch('/api/v1/notification-preferences', body: {field: newVal});
          add(LoadNotificationPrefs());
        } catch (e) {
          emit(NotificationPrefsError(e.toString()));
        }
      }
    };
  }
}
