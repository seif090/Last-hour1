import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/api_client.dart';
import 'services/location_service.dart';
import 'services/map_service.dart';
import 'services/payment_service.dart';
import 'services/websocket_service.dart';
import 'services/notification_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/bloc/offers_bloc.dart';
import 'features/orders/presentation/bloc/order_track_bloc.dart';
import 'features/store_detail/presentation/bloc/store_detail_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lasthour_shared/constants/api_constants.dart';
import 'package:lasthour_shared/src/services/connectivity_service.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Core
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // Connectivity
  final connectivity = ConnectivityService();
  connectivity.initialize();
  sl.registerLazySingleton<ConnectivityService>(() => connectivity);

  // Services
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(baseUrl: ApiConstants.baseUrl, connectivity: sl<ConnectivityService>()),
  );

  sl.registerLazySingleton<LocationService>(
    () => LocationService(),
  );

  sl.registerLazySingleton<MapService>(
    () => MapService(),
  );

  sl.registerLazySingleton<PaymentService>(
    () => PaymentService(sl<ApiClient>()),
  );

  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(sl<ApiClient>()),
  );

  // WebSocket — initialized with empty token, updated after login via updateToken()
  sl.registerLazySingleton<WebSocketService>(
    () => WebSocketService(baseUrl: ApiConstants.wsUrl, token: ''),
  );

  // BLoCs
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      api: sl<ApiClient>(),
      storage: sl<FlutterSecureStorage>(),
    ),
  );

  sl.registerFactoryParam<OffersBloc, ApiClient, WebSocketService>(
    (api, ws) => OffersBloc(
      api: api ?? sl<ApiClient>(),
      ws: ws ?? sl<WebSocketService>(),
      location: sl<LocationService>(),
    ),
  );

  sl.registerFactoryParam<OrderTrackBloc, ApiClient, WebSocketService>(
    (api, ws) => OrderTrackBloc(
      api: api ?? sl<ApiClient>(),
      ws: ws ?? sl<WebSocketService>(),
    ),
  );
}
