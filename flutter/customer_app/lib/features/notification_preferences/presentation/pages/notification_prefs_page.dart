import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notification_prefs_bloc.dart';
import '../../../../services/api_client.dart';
import '../../../../injector.dart';

class NotificationPrefsPage extends StatefulWidget {
  const NotificationPrefsPage({super.key});

  @override
  State<NotificationPrefsPage> createState() => _NotificationPrefsPageState();
}

class _NotificationPrefsPageState extends State<NotificationPrefsPage> {
  late final NotificationPrefsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = NotificationPrefsBloc(api: sl<ApiClient>())..add(LoadNotificationPrefs());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<NotificationPrefsBloc, NotificationPrefsState>(
          builder: (context, state) {
            if (state is NotificationPrefsLoading || state is NotificationPrefsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is NotificationPrefsError) {
              return Center(child: Text(state.message));
            }
            if (state is NotificationPrefsLoaded) {
              final p = state.prefs;
              return ListView(
                children: [
                  _switchTile(p, 'Push Notifications', 'pushEnabled', const Icon(Icons.notifications_outlined)),
                  _switchTile(p, 'Order Confirmed', 'orderConfirmed', const Icon(Icons.check_circle_outline)),
                  _switchTile(p, 'Order Ready', 'orderReady', const Icon(Icons.shopping_bag_outlined)),
                  _switchTile(p, 'Nearby Offers', 'nearbyOffers', const Icon(Icons.near_me_outlined)),
                  _switchTile(p, 'Promotions', 'promotions', const Icon(Icons.local_offer_outlined)),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Push notifications must be enabled for any of the below to work.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _switchTile(Map<String, dynamic> prefs, String label, String field, Icon icon) {
    final value = prefs[field] as bool? ?? true;
    final enabled = _bloc.state is NotificationPrefsLoaded;
    return SwitchListTile(
      secondary: icon,
      title: Text(label),
      value: value,
      onChanged: enabled ? (_) => _bloc.add(_eventForField(field)) : null,
    );
  }

  NotificationPrefsEvent _eventForField(String field) {
    switch (field) {
      case 'pushEnabled': return TogglePushEnabled();
      case 'orderConfirmed': return ToggleOrderConfirmed();
      case 'orderReady': return ToggleOrderReady();
      case 'nearbyOffers': return ToggleNearbyOffers();
      case 'promotions': return TogglePromotions();
      default: return TogglePushEnabled();
    }
  }
}
