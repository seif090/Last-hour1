import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../services/api_client.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested(this.email, this.password);
}
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String businessName;
  final String businessType;
  final String? description;
  final String? taxId;
  const RegisterRequested({required this.email, required this.password, required this.businessName, required this.businessType, this.description, this.taxId});
}
class LogoutRequested extends AuthEvent {}

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final String token;
  final String merchantId;
  const Authenticated({required this.token, required this.merchantId});
  @override
  List<Object?> get props => [token, merchantId];
}
class Unauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient _api;
  final FlutterSecureStorage _storage;

  AuthBloc({required ApiClient api, required FlutterSecureStorage storage})
      : _api = api,
        _storage = storage,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);

    add(AppStarted());
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final token = await _storage.read(key: 'merchant_token');
    final merchantId = await _storage.read(key: 'merchant_id');
    if (token != null && merchantId != null) {
      _api.setToken(token);
      emit(Authenticated(token: token, merchantId: merchantId));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _api.post('/api/v1/auth/login', body: {
        'email': event.email,
        'password': event.password,
      });
      if (response.isSuccess && response.data != null) {
        final d = response.data!;
        final token = (d['accessToken'] ?? d['access_token']) as String;
        final user = d['user'] as Map<String, dynamic>;

        if (user['role'] != 'merchant') {
          emit(const AuthError('This account is not a merchant'));
          return;
        }

        await _storage.write(key: 'merchant_token', value: token);
        await _storage.write(key: 'merchant_id', value: user['id'] as String);
        await _storage.write(key: 'merchant_email', value: user['email'] as String);

        _api.setToken(token);
        emit(Authenticated(token: token, merchantId: user['id'] as String));
      } else {
        emit(AuthError(response.error ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await _storage.deleteAll();
    _api.setToken(null);
    emit(Unauthenticated());
  }

  Future<void> _onRegister(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _api.post('/api/v1/auth/register', body: {
        'email': event.email,
        'password': event.password,
        'role': 'merchant',
      });
      if (response.isSuccess && response.data != null) {
        final d = response.data!;
        final token = (d['accessToken'] ?? d['access_token']) as String;
        _api.setToken(token);

        final merchantResp = await _api.post('/api/v1/merchant/register', body: {
          'businessName': event.businessName,
          'businessType': event.businessType,
          'description': event.description,
          'taxId': event.taxId,
        });
        if (merchantResp.isSuccess) {
          await _storage.write(key: 'merchant_token', value: token);
          await _storage.write(key: 'merchant_id', value: (d['user'] as Map<String, dynamic>)['id'] as String);
          emit(Authenticated(token: token, merchantId: (d['user'] as Map<String, dynamic>)['id'] as String));
        } else {
          emit(AuthError(merchantResp.error ?? 'Merchant registration failed'));
        }
      } else {
        emit(AuthError(response.error ?? 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
