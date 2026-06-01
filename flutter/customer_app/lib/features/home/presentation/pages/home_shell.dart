import 'package:flutter/material.dart';
import '../../../../injector.dart';
import 'package:lasthour_shared/src/services/connectivity_service.dart';
import 'package:lasthour_shared/src/widgets/offline_banner.dart';

class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<bool>(
        stream: sl<ConnectivityService>().connectivityStream,
        initialData: sl<ConnectivityService>().isConnected,
        builder: (context, snapshot) {
          final isOffline = snapshot.data == false;
          return Column(
            children: [
              if (isOffline) const OfflineBanner(),
              Expanded(child: navigationShell),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: 'Offers',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
        ],
      ),
    );
  }
}
