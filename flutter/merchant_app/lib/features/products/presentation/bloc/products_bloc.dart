import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../services/api_client.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();
  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductsEvent {}
class CreateProduct extends ProductsEvent {
  final Map<String, dynamic> data;
  const CreateProduct(this.data);
}
class UpdateProduct extends ProductsEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateProduct(this.id, this.data);
}
class DeleteProduct extends ProductsEvent {
  final String id;
  const DeleteProduct(this.id);
}

abstract class ProductsState extends Equatable {
  const ProductsState();
  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {}
class ProductsLoading extends ProductsState {}
class ProductsLoaded extends ProductsState {
  final List<Map<String, dynamic>> products;
  const ProductsLoaded({required this.products});
  @override
  List<Object?> get props => [products];
}
class ProductsError extends ProductsState {
  final String message;
  const ProductsError(this.message);
  @override
  List<Object?> get props => [message];
}
class ProductOperationSuccess extends ProductsState {
  final String message;
  const ProductOperationSuccess(this.message);
}

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ApiClient _api;

  ProductsBloc({required ApiClient api}) : _api = api, super(ProductsInitial()) {
    on<LoadProducts>(_onLoad);
    on<CreateProduct>(_onCreate);
    on<UpdateProduct>(_onUpdate);
    on<DeleteProduct>(_onDelete);
  }

  Future<void> _onLoad(LoadProducts event, Emitter<ProductsState> emit) async {
    emit(ProductsLoading());
    try {
      final response = await _api.get('/api/v1/merchant/products');
      if (response.isSuccess && response.data != null) {
        final list = response.data!['products'] as List<dynamic>? ?? [];
        emit(ProductsLoaded(products: list.cast<Map<String, dynamic>>()));
      } else {
        emit(ProductsError(response.error ?? 'Failed to load products'));
      }
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateProduct event, Emitter<ProductsState> emit) async {
    emit(ProductsLoading());
    try {
      final response = await _api.post('/api/v1/merchant/products', body: event.data);
      if (response.isSuccess) {
        add(LoadProducts());
      } else {
        emit(ProductsError(response.error ?? 'Failed to create product'));
      }
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateProduct event, Emitter<ProductsState> emit) async {
    emit(ProductsLoading());
    try {
      final response = await _api.patch('/api/v1/merchant/products/${event.id}', body: event.data);
      if (response.isSuccess) {
        add(LoadProducts());
      } else {
        emit(ProductsError(response.error ?? 'Failed to update product'));
      }
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteProduct event, Emitter<ProductsState> emit) async {
    emit(ProductsLoading());
    try {
      final response = await _api.delete('/api/v1/merchant/products/${event.id}');
      if (response.isSuccess) {
        add(LoadProducts());
      } else {
        emit(ProductsError(response.error ?? 'Failed to delete product'));
      }
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }
}
