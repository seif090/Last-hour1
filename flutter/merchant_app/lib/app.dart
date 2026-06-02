import 'package:flutter/material.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/merchant_auth_page.dart';
import 'features/dashboard/presentation/pages/merchant_dashboard_page.dart';
import 'features/offers/presentation/pages/merchant_offers_page.dart';
import 'features/orders/presentation/pages/merchant_incoming_orders_page.dart';
import 'features/products/presentation/pages/products_page.dart';
import 'features/analytics/presentation/pages/merchant_analytics_page.dart';
import 'features/coupons/presentation/pages/coupons_page.dart';
import 'features/staff/presentation/pages/staff_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injector.dart';
import 'package:lasthour_shared/lasthour_shared.dart';

class LastHourMerchantApp extends StatelessWidget {
  const LastHourMerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: MaterialApp(
        title: 'Last Hour — Merchant',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        builder: (context, child) {
          return StreamBuilder<bool>(
            stream: sl<ConnectivityService>().connectivityStream,
            initialData: sl<ConnectivityService>().isConnected,
            builder: (context, snapshot) {
              final isOffline = snapshot.data == false;
              return Column(
                children: [
                  if (isOffline) const OfflineBanner(),
                  Expanded(child: child ?? const SizedBox.shrink()),
                ],
              );
            },
          );
        },
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Unauthenticated || state is AuthInitial) {
              return const MerchantAuthPage();
            }
            return const MerchantShell();
          },
        ),
      ),
    );
  }
}

class MerchantShell extends StatefulWidget {
  const MerchantShell({super.key});

  @override
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  int _index = 0;

  final _pages = const [
    MerchantDashboardPage(),
    MerchantOffersPage(),
    ProductsPage(),
    MerchantIncomingOrdersPage(),
    CouponsPage(),
    MerchantAnalyticsPage(),
    StaffPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.local_offer_outlined), selectedIcon: Icon(Icons.local_offer), label: 'Offers'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.card_giftcard_outlined), selectedIcon: Icon(Icons.card_giftcard), label: 'Coupons'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group), label: 'Staff'),
        ],
      ),
    );
  }
}

// MerchantAuthPage moved to features/auth/presentation/pages/merchant_auth_page.dart
