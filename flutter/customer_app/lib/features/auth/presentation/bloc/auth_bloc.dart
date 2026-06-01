import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../services/api_client.dart';

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
  final String role;
  const RegisterRequested(this.email, this.password, this.role);
}
class LogoutRequested extends AuthEvent {}
class TokenRefreshed extends AuthEvent {
  final String token;
  const TokenRefreshed(this.token);
}

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final String token;
  final String userId;
  final String email;
  final String role;
  const Authenticated({required this.token, required this.userId, required this.email, required this.role});
  @override
  List<Object?> get props => [token, userId, role];
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
    on<TokenRefreshed>(_onTokenRefreshed);

    add(AppStarted());
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final token = await _storage.read(key: 'access_token');
    final userId = await _storage.read(key: 'user_id');
    final email = await _storage.read(key: 'user_email');
    final role = await _storage.read(key: 'user_role');

    if (token != null && userId != null) {
      _api.setToken(token);
      emit(Authenticated(token: token, userId: userId, email: email ?? '', role: role ?? 'customer'));
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
        final token = d['accessToken'] ?? d['access_token'];
        final user = d['user'] as Map<String, dynamic>;

        await _storage.write(key: 'access_token', value: token);
        await _storage.write(key: 'user_id', value: user['id']);
        await _storage.write(key: 'user_email', value: user['email']);
        await _storage.write(key: 'user_role', value: user['role']);

        _api.setToken(token);
        emit(Authenticated(
          token: token,
          userId: user['id'],
          email: user['email'],
          role: user['role'],
        ));
      } else {
        emit(AuthError(response.error ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegister(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _api.post('/api/v1/auth/register', body: {
        'email': event.email,
        'password': event.password,
        'role': event.role,
      });

      if (response.isSuccess && response.data != null) {
        final d = response.data!;
        final token = d['accessToken'] ?? d['access_token'];
        final user = d['user'] as Map<String, dynamic>;

        await _storage.write(key: 'access_token', value: token);
        await _storage.write(key: 'user_id', value: user['id']);
        await _storage.write(key: 'user_email', value: user['email']);
        await _storage.write(key: 'user_role', value: user['role']);

        _api.setToken(token);
        emit(Authenticated(
          token: token,
          userId: user['id'],
          email: user['email'],
          role: user['role'],
        ));
      } else {
        emit(AuthError(response.error ?? 'Registration failed'));
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

  void _onTokenRefreshed(TokenRefreshed event, Emitter<AuthState> emit) {
    _api.setToken(event.token);
    if (state is Authenticated) {
      final current = state as Authenticated;
      emit(Authenticated(
        token: event.token,
        userId: current.userId,
        email: current.email,
        role: current.role,
      ));
    }
  }
}
