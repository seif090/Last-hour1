import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/api_client.dart';
import 'features/dashboard/presentation/pages/merchant_dashboard_page.dart';
import 'features/offers/presentation/pages/merchant_offers_page.dart';
import 'features/orders/presentation/pages/merchant_incoming_orders_page.dart';

void main() {
  runApp(const LastHourMerchantApp());
}

class LastHourMerchantApp extends StatelessWidget {
  const LastHourMerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Last Hour — Merchant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE53935),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const MerchantShell(),
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
