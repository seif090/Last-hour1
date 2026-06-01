import 'package:flutter/material.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/merchant_auth_page.dart';
import 'features/dashboard/presentation/pages/merchant_dashboard_page.dart';
import 'features/offers/presentation/pages/merchant_offers_page.dart';
import 'features/orders/presentation/pages/merchant_incoming_orders_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injector.dart';
import 'package:lasthour_shared/src/services/connectivity_service.dart';
import 'package:lasthour_shared/src/widgets/offline_banner.dart';

class LastHourMerchantApp extends StatelessWidget {
  const LastHourMerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: MaterialApp(
        title: 'Last Hour — Merchant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFFE53935),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
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
    MerchantIncomingOrdersPage(),
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
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
        ],
      ),
    );
  }
}

// MerchantAuthPage moved to features/auth/presentation/pages/merchant_auth_page.dart
