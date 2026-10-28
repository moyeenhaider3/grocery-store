import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_event.dart';
import '../../repositories/admin_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/cart_repository.dart';
import '../../repositories/catalog_repository.dart';
import '../../repositories/order_repository.dart';
import '../network/api_client.dart';
import '../router/app_router.dart';

final sl = GetIt.instance; // service locator

Future<void> initDependencies() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl<SharedPreferences>()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(apiClient: sl<ApiClient>(), prefs: sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<AdminRepository>(() => AdminRepository(apiClient: sl<ApiClient>()));
  sl.registerLazySingleton<CatalogRepository>(() => CatalogRepository(apiClient: sl<ApiClient>()));

  sl.registerLazySingleton<CartRepository>(() => CartRepository(apiClient: sl<ApiClient>()));
  sl.registerLazySingleton<OrderRepository>(() => OrderRepository(apiClient: sl<ApiClient>()));

  // Session lasts the whole app run, so AuthBloc is a singleton.
  sl.registerLazySingleton<AuthBloc>(() => AuthBloc(authRepository: sl<AuthRepository>()));

  // The cart lives for the whole app run, tied to the login state.
  sl.registerLazySingleton<CartBloc>(() => CartBloc(cartRepository: sl<CartRepository>()));

  sl<AuthBloc>().stream.listen((s) {
    if (s.status == AuthStatus.authenticated) sl<CartBloc>().add(CartLoadRequested());
    if (s.status == AuthStatus.unauthenticated) sl<CartBloc>().add(CartCleared());
  });

  sl.registerLazySingleton<AppRouter>(() => AppRouter(sl<AuthBloc>()));

  // Avoids a constructor cycle ApiClient -> AuthBloc -> AuthRepository -> ApiClient.
  sl<ApiClient>().onUnauthorized = () => sl<AuthBloc>().add(SessionExpired());
}
