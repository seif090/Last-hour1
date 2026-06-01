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

GoRouter appRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authBloc,
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
                builder: (_, __) => const MapExplorePage(),
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
        ],
      ),
      GoRoute(
        path: '/offers/:id',
        builder: (_, state) => OfferDetailPage(offerId: state.pathParameters['id']!),
      ),
    ],
  );
}
