import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../services/api_client.dart';

abstract class AdminAuthEvent extends Equatable {
  const AdminAuthEvent();
  @override
  List<Object?> get props => [];
}

class AdminLogin extends AdminAuthEvent {
  final String email;
  final String password;
  const AdminLogin(this.email, this.password);
}

class AdminLogout extends AdminAuthEvent {}

class CheckAdminAuth extends AdminAuthEvent {}

abstract class AdminAuthState extends Equatable {
  const AdminAuthState();
  @override
  List<Object?> get props => [];
}

class AdminAuthInitial extends AdminAuthState {}
class AdminAuthLoading extends AdminAuthState {}
class AdminAuthenticated extends AdminAuthState {}
class AdminUnauthenticated extends AdminAuthState {}
class AdminAuthError extends AdminAuthState {
  final String message;
  const AdminAuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminAuthBloc extends Bloc<AdminAuthEvent, AdminAuthState> {
  final ApiClient _api;

  AdminAuthBloc({required ApiClient api})
      : _api = api,
        super(AdminAuthInitial()) {
    on<CheckAdminAuth>(_onCheck);
    on<AdminLogin>(_onLogin);
    on<AdminLogout>(_onLogout);
  }

  void _onCheck(CheckAdminAuth event, Emitter<AdminAuthState> emit) {
    if (_api._token != null) {
      emit(AdminAuthenticated());
    } else {
      emit(AdminUnauthenticated());
    }
  }

  Future<void> _onLogin(AdminLogin event, Emitter<AdminAuthState> emit) async {
    emit(AdminAuthLoading());
    try {
      final response = await _api.post('/api/v1/auth/login', body: {
        'email': event.email,
        'password': event.password,
      });
      if (response.isSuccess && response.data != null) {
        final token = response.data!['token'] as String?;
        final role = response.data!['user']?['role'] as String?;
        if (token != null && role == 'admin') {
          await _api.saveToken(token);
          emit(AdminAuthenticated());
        } else {
          emit(const AdminAuthError('Admin access required'));
        }
      } else {
        emit(AdminAuthError(response.error ?? 'Login failed'));
      }
    } catch (e) {
      emit(AdminAuthError(e.toString()));
    }
  }

  Future<void> _onLogout(AdminLogout event, Emitter<AdminAuthState> emit) async {
    await _api.clearToken();
    emit(AdminUnauthenticated());
  }
}
