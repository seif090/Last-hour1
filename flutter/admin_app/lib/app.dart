import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/presentation/bloc/admin_auth_bloc.dart';
import 'features/auth/presentation/pages/admin_auth_page.dart';
import 'features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'features/users/presentation/pages/admin_users_page.dart';
import 'features/merchants/presentation/pages/admin_merchants_page.dart';
import 'features/orders/presentation/pages/admin_orders_page.dart';
import 'features/offers/presentation/pages/admin_offers_page.dart';
import 'features/coupons/presentation/pages/admin_coupons_page.dart';
import 'features/referrals/presentation/pages/admin_referrals_page.dart';
import 'features/system/presentation/pages/admin_system_page.dart';
import 'injector.dart';
import 'package:lasthour_shared/lasthour_shared.dart';

class LastHourAdminApp extends StatelessWidget {
  const LastHourAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminAuthBloc(api: sl<ApiClient>())..add(CheckAdminAuth()),
      child: MaterialApp(
        title: 'Last Hour — Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: BlocBuilder<AdminAuthBloc, AdminAuthState>(
          builder: (context, state) {
            if (state is AdminAuthenticated) {
              return const AdminShell();
            }
            return const AdminAuthPage();
          },
        ),
      ),
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _pages = const [
    AdminDashboardPage(),
    AdminUsersPage(),
    AdminMerchantsPage(),
    AdminOrdersPage(),
    AdminOffersPage(),
    AdminCouponsPage(),
    AdminReferralsPage(),
    AdminSystemPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Merchants'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.local_offer), label: 'Offers'),
          NavigationDestination(icon: Icon(Icons.card_giftcard), label: 'Coupons'),
          NavigationDestination(icon: Icon(Icons.share), label: 'Referrals'),
          NavigationDestination(icon: Icon(Icons.monitor_heart), label: 'System'),
        ],
      ),
    );
  }
}
