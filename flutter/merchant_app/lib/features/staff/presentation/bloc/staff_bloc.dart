import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/api_client.dart';
import '../../../injector.dart';

abstract class StaffEvent {}

class LoadStaff extends StaffEvent {}

class InviteStaff extends StaffEvent {
  final String email;
  final String name;
  final String role;
  InviteStaff(this.email, this.name, this.role);
}

class RemoveStaff extends StaffEvent {
  final String id;
  RemoveStaff(this.id);
}

class ToggleStaffActive extends StaffEvent {
  final String id;
  final bool isActive;
  ToggleStaffActive(this.id, this.isActive);
}

abstract class StaffState {}

class StaffInitial extends StaffState {}

class StaffLoading extends StaffState {}

class StaffLoaded extends StaffState {
  final List<Map<String, dynamic>> members;
  StaffLoaded(this.members);
}

class StaffError extends StaffState {
  final String message;
  StaffError(this.message);
}

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final ApiClient _api;

  StaffBloc({required ApiClient api})
      : _api = api,
        super(StaffInitial()) {
    on<LoadStaff>(_onLoad);
    on<InviteStaff>(_onInvite);
    on<RemoveStaff>(_onRemove);
    on<ToggleStaffActive>(_onToggle);
  }

  void _onLoad(LoadStaff event, Emitter<StaffState> emit) async {
    emit(StaffLoading());
    try {
      final resp = await _api.get('/api/v1/merchant/staff');
      if (resp.isSuccess && resp.data != null) {
        final list = (resp.data!['data'] as List? ?? []).cast<Map<String, dynamic>>();
        emit(StaffLoaded(list));
      } else {
        emit(StaffError(resp.error ?? 'Failed to load'));
      }
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  void _onInvite(InviteStaff event, Emitter<StaffState> emit) async {
    try {
      await _api.post('/api/v1/merchant/staff', body: {
        'email': event.email,
        'name': event.name,
        'role': event.role,
      });
      add(LoadStaff());
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  void _onRemove(RemoveStaff event, Emitter<StaffState> emit) async {
    try {
      await _api.delete('/api/v1/merchant/staff/${event.id}');
      add(LoadStaff());
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  void _onToggle(ToggleStaffActive event, Emitter<StaffState> emit) async {
    try {
      await _api.patch('/api/v1/merchant/staff/${event.id}', body: {'isActive': event.isActive});
      add(LoadStaff());
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }
}
