import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lasthour_shared/models/user.dart';
import '../../../../services/api_client.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {}
class UpdateProfile extends ProfileEvent {
  final String? phone;
  final String? avatarUrl;
  const UpdateProfile({this.phone, this.avatarUrl});
  @override
  List<Object?> get props => [phone, avatarUrl];
}

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}
class ProfileLoaded extends ProfileState {
  final User user;
  const ProfileLoaded({required this.user});
  @override
  List<Object?> get props => [user];
}
class ProfileUpdateSuccess extends ProfileState {
  final User user;
  final String message;
  const ProfileUpdateSuccess({required this.user, this.message = 'Profile updated'});
  @override
  List<Object?> get props => [user, message];
}
class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ApiClient _api;

  ProfileBloc({required ApiClient api}) : _api = api, super(ProfileInitial()) {
    on<LoadProfile>(_onLoad);
    on<UpdateProfile>(_onUpdate);
  }

  Future<void> _onLoad(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final response = await _api.get('/api/v1/users/me');
      if (response.isSuccess && response.data != null) {
        final userData = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
        final user = User.fromJson(userData);
        emit(ProfileLoaded(user: user));
      } else {
        emit(ProfileError(response.error ?? 'Failed to load profile'));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateProfile event, Emitter<ProfileState> emit) async {
    if (state is! ProfileLoaded) return;
    emit(ProfileLoading());
    try {
      final body = <String, dynamic>{};
      if (event.phone != null) body['phone'] = event.phone;
      if (event.avatarUrl != null) body['avatarUrl'] = event.avatarUrl;

      final response = await _api.patch('/api/v1/users/me', body: body);
      if (response.isSuccess && response.data != null) {
        final userData = response.data!['data'] as Map<String, dynamic>? ?? response.data!;
        final user = User.fromJson(userData);
        emit(ProfileUpdateSuccess(user: user));
      } else {
        emit(ProfileError(response.error ?? 'Failed to update profile'));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
