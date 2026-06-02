import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/home/presentation/pages/home_shell.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/map_explore_page.dart';
import '../../features/offer_detail/presentation/pages/offer_detail_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';
import '../../features/orders/presentation/pages/order_track_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/store_detail/presentation/pages/store_detail_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/addresses/presentation/pages/addresses_page.dart';
import '../../features/notification_preferences/presentation/pages/notification_prefs_page.dart';
import '../../features/payment_methods/presentation/pages/payment_methods_page.dart';

class _AuthStateNotifier extends ChangeNotifier {
  final StreamSubscription _sub;
  _AuthStateNotifier(AuthBloc bloc) : _sub = bloc.stream.listen((_) => notifyListeners());
  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}

GoRouter appRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthStateNotifier(authBloc),
    redirect: (context, state) {
      final loggedIn = authBloc.state is Authenticated;
      final onAuth = state.matchedLocation == '/auth';

      if (!loggedIn && !onAuth) return '/auth';
      if (loggedIn && onAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (_, __) => const AuthPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (_, state) {
                  final lat = double.tryParse(state.uri.queryParameters['lat'] ?? '');
                  final lng = double.tryParse(state.uri.queryParameters['lng'] ?? '');
                  return MapExplorePage(focusLat: lat, focusLng: lng);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (_, __) => const OrdersPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => OrderDetailPage(orderId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'track',
                        builder: (_, state) => OrderTrackPage(orderId: state.pathParameters['id']!),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (_, __) => const FavoritesPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/offers/:id',
        builder: (_, state) => OfferDetailPage(offerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/stores/:id',
        builder: (_, state) => StoreDetailPage(storeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfilePage(),
      ),
      GoRoute(
        path: '/addresses',
        builder: (_, __) => const AddressesPage(),
      ),
      GoRoute(
        path: '/notification-preferences',
        builder: (_, __) => const NotificationPrefsPage(),
      ),
      GoRoute(
        path: '/payment-methods',
        builder: (_, __) => const PaymentMethodsPage(),
      ),
    ],
  );
}
