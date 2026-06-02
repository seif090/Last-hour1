import 'package:get_it/get_it.dart';
import 'services/api_client.dart';

final sl = GetIt.instance;

Future<void> initializeAdminDependencies() async {
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  await sl<ApiClient>().loadToken();
}
