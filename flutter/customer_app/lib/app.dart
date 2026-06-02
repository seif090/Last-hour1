import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/bloc/offers_bloc.dart';
import 'injector.dart';
import 'package:lasthour_shared/lasthour_shared.dart';

class LastHourCustomerApp extends StatelessWidget {
  const LastHourCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authBloc = sl<AuthBloc>();
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider(create: (_) => sl<OffersBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Last Hour',
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter(authBloc),
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
      ),
    );
  }
}
