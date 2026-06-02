import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lasthour_shared/models/address.dart';
import '../../../../injector.dart';
import '../../../../services/api_client.dart';

abstract class AddressesEvent extends Equatable {
  const AddressesEvent();
  @override
  List<Object?> get props => [];
}

class LoadAddresses extends AddressesEvent {}
class CreateAddress extends AddressesEvent {
  final Map<String, dynamic> data;
  const CreateAddress(this.data);
}
class UpdateAddress extends AddressesEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateAddress(this.id, this.data);
}
class DeleteAddress extends AddressesEvent {
  final String id;
  const DeleteAddress(this.id);
}

abstract class AddressesState extends Equatable {
  const AddressesState();
  @override
  List<Object?> get props => [];
}

class AddressesInitial extends AddressesState {}
class AddressesLoading extends AddressesState {}
class AddressesLoaded extends AddressesState {
  final List<Address> addresses;
  const AddressesLoaded({this.addresses = const []});
  @override
  List<Object?> get props => [addresses];
}
class AddressesError extends AddressesState {
  final String message;
  const AddressesError(this.message);
  @override
  List<Object?> get props => [message];
}

class AddressesBloc extends Bloc<AddressesEvent, AddressesState> {
  final ApiClient _api;

  AddressesBloc({required ApiClient api})
      : _api = api,
        super(AddressesInitial()) {
    on<LoadAddresses>(_onLoad);
    on<CreateAddress>(_onCreate);
    on<UpdateAddress>(_onUpdate);
    on<DeleteAddress>(_onDelete);
  }

  Future<void> _onLoad(LoadAddresses event, Emitter<AddressesState> emit) async {
    emit(AddressesLoading());
    try {
      final response = await _api.get('/api/v1/addresses');
      if (response.isSuccess && response.data != null) {
        final list = (response.data!['data'] as List? ?? [])
            .map((j) => Address.fromJson(j as Map<String, dynamic>))
            .toList();
        emit(AddressesLoaded(addresses: list));
      } else {
        emit(AddressesError(response.error ?? 'Failed to load addresses'));
      }
    } catch (e) {
      emit(AddressesError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateAddress event, Emitter<AddressesState> emit) async {
    try {
      final response = await _api.post('/api/v1/addresses', body: event.data);
      if (response.isSuccess) {
        add(const LoadAddresses());
      } else {
        emit(AddressesError(response.error ?? 'Failed to create address'));
      }
    } catch (e) {
      emit(AddressesError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateAddress event, Emitter<AddressesState> emit) async {
    try {
      final response = await _api.patch('/api/v1/addresses/${event.id}', body: event.data);
      if (response.isSuccess) {
        add(const LoadAddresses());
      } else {
        emit(AddressesError(response.error ?? 'Failed to update address'));
      }
    } catch (e) {
      emit(AddressesError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteAddress event, Emitter<AddressesState> emit) async {
    try {
      final response = await _api.delete('/api/v1/addresses/${event.id}');
      if (response.isSuccess) {
        add(const LoadAddresses());
      } else {
        emit(AddressesError(response.error ?? 'Failed to delete address'));
      }
    } catch (e) {
      emit(AddressesError(e.toString()));
    }
  }
}
