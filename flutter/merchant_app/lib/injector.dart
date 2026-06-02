import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/api_client.dart';
import 'services/websocket_service.dart';
import 'features/offers/presentation/bloc/merchant_offers_bloc.dart';
import 'features/orders/presentation/bloc/incoming_orders_bloc.dart';
import 'features/products/presentation/bloc/products_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lasthour_shared/src/services/connectivity_service.dart';
import 'package:lasthour_shared/constants/api_constants.dart';

final sl = GetIt.instance;

Future<void> initializeMerchantDependencies() async {
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // Connectivity
  final connectivity = ConnectivityService();
  connectivity.initialize();
  sl.registerLazySingleton<ConnectivityService>(() => connectivity);

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: ApiConstants.baseUrl, connectivity: sl<ConnectivityService>()),
  );

  sl.registerLazySingleton<MerchantWebSocketService>(
    () => MerchantWebSocketService(
      baseUrl: ApiConstants.wsUrl,
      token: '',
      merchantId: '',
    ),
  );

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(api: sl<ApiClient>(), storage: sl<FlutterSecureStorage>()),
  );

  sl.registerFactory<MerchantOffersBloc>(
    () => MerchantOffersBloc(api: sl<ApiClient>()),
  );

  sl.registerFactory<IncomingOrdersBloc>(
    () => IncomingOrdersBloc(
      api: sl<ApiClient>(),
      ws: sl<MerchantWebSocketService>(),
    ),
  );

  sl.registerFactory<ProductsBloc>(
    () => ProductsBloc(api: sl<ApiClient>()),
  );
}
