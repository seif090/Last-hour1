# Last Hour — Flutter Mobile Apps

## Folder Structure (Feature-First Architecture)

```
flutter/
├── packages/
│   ├── customer_app/               # Customer-facing app
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── app.dart
│   │   │   ├── bootstrap.dart
│   │   │   ├── core/
│   │   │   │   ├── constants/
│   │   │   │   │   ├── app_colors.dart
│   │   │   │   │   ├── app_text_styles.dart
│   │   │   │   │   └── app_dimensions.dart
│   │   │   │   ├── network/
│   │   │   │   │   ├── api_client.dart           # Dio instance
│   │   │   │   │   ├── api_interceptors.dart     # Auth, retry, logging
│   │   │   │   │   ├── api_endpoints.dart
│   │   │   │   │   └── api_exceptions.dart
│   │   │   │   ├── router/
│   │   │   │   │   ├── app_router.dart           # GoRouter
│   │   │   │   │   └── route_names.dart
│   │   │   │   ├── theme/
│   │   │   │   │   ├── app_theme.dart
│   │   │   │   │   └── app_theme_data.dart
│   │   │   │   ├── utils/
│   │   │   │   │   ├── validators.dart
│   │   │   │   │   ├── formatters.dart
│   │   │   │   │   └── geo_utils.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── app_button.dart
│   │   │   │       ├── app_text_field.dart
│   │   │   │       ├── loading_overlay.dart
│   │   │   │       ├── error_screen.dart
│   │   │   │       └── infinite_scroll_list.dart
│   │   │   │
│   │   │   ├── features/
│   │   │   │   ├── auth/
│   │   │   │   │   ├── data/
│   │   │   │   │   │   ├── auth_repository.dart
│   │   │   │   │   │   ├── auth_remote_source.dart
│   │   │   │   │   │   └── models/
│   │   │   │   │   │       ├── user_model.dart
│   │   │   │   │   │       └── token_model.dart
│   │   │   │   │   ├── domain/
│   │   │   │   │   │   ├── auth_repository_interface.dart
│   │   │   │   │   │   └── entities/
│   │   │   │   │   │       └── user.dart
│   │   │   │   │   ├── presentation/
│   │   │   │   │   │   ├── bloc/
│   │   │   │   │   │   │   ├── auth_bloc.dart
│   │   │   │   │   │   │   ├── auth_event.dart
│   │   │   │   │   │   │   └── auth_state.dart
│   │   │   │   │   │   ├── pages/
│   │   │   │   │   │   │   ├── login_page.dart
│   │   │   │   │   │   │   ├── register_page.dart
│   │   │   │   │   │   │   └── otp_verification_page.dart
│   │   │   │   │   │   └── widgets/
│   │   │   │   │   │       ├── login_form.dart
│   │   │   │   │   │       └── social_login_button.dart
│   │   │   │   │   └── auth_injector.dart        # Service locator wiring
│   │   │   │   │
│   │   │   │   ├── home/
│   │   │   │   │   ├── data/
│   │   │   │   │   │   ├── home_repository.dart
│   │   │   │   │   │   └── models/
│   │   │   │   │   │       ├── offer_model.dart
│   │   │   │   │   │       └── store_model.dart
│   │   │   │   │   ├── domain/
│   │   │   │   │   │   ├── home_repository_interface.dart
│   │   │   │   │   │   └── entities/
│   │   │   │   │   │       ├── offer.dart
│   │   │   │   │   │       └── store.dart
│   │   │   │   │   ├── presentation/
│   │   │   │   │   │   ├── bloc/
│   │   │   │   │   │   │   ├── offers_bloc.dart
│   │   │   │   │   │   │   ├── offers_event.dart
│   │   │   │   │   │   │   ├── offers_state.dart
│   │   │   │   │   │   │   ├── map_bloc.dart
│   │   │   │   │   │   │   ├── map_event.dart
│   │   │   │   │   │   │   └── map_state.dart
│   │   │   │   │   │   ├── pages/
│   │   │   │   │   │   │   ├── home_page.dart
│   │   │   │   │   │   │   └── map_explore_page.dart
│   │   │   │   │   │   └── widgets/
│   │   │   │   │   │       ├── offer_card.dart
│   │   │   │   │   │       ├── offer_timer.dart
│   │   │   │   │   │       ├── category_chips.dart
│   │   │   │   │   │       └── stock_indicator.dart
│   │   │   │   │   └── home_injector.dart
│   │   │   │   │
│   │   │   │   ├── offer_detail/
│   │   │   │   │   ├── data/
│   │   │   │   │   │   └── offer_detail_repository.dart
│   │   │   │   │   ├── domain/
│   │   │   │   │   │   └── offer_detail_repository_interface.dart
│   │   │   │   │   ├── presentation/
│   │   │   │   │   │   ├── bloc/
│   │   │   │   │   │   │   ├── offer_detail_bloc.dart
│   │   │   │   │   │   │   ├── offer_detail_event.dart
│   │   │   │   │   │   │   └── offer_detail_state.dart
│   │   │   │   │   │   ├── pages/
│   │   │   │   │   │   │   └── offer_detail_page.dart
│   │   │   │   │   │   └── widgets/
│   │   │   │   │   │       ├── stock_countdown.dart
│   │   │   │   │   │       ├── quantity_selector.dart
│   │   │   │   │   │       └── store_info_card.dart
│   │   │   │   │   └── offer_detail_injector.dart
│   │   │   │   │
│   │   │   │   ├── orders/
│   │   │   │   │   ├── data/
│   │   │   │   │   │   ├── order_repository.dart
│   │   │   │   │   │   └── models/
│   │   │   │   │   │       ├── order_model.dart
│   │   │   │   │   │       └── order_track_model.dart
│   │   │   │   │   ├── domain/
│   │   │   │   │   │   ├── order_repository_interface.dart
│   │   │   │   │   │   └── entities/
│   │   │   │   │   │       ├── order.dart
│   │   │   │   │   │       └── order_status.dart
│   │   │   │   │   ├── presentation/
│   │   │   │   │   │   ├── bloc/
│   │   │   │   │   │   │   ├── orders_bloc.dart
│   │   │   │   │   │   │   ├── orders_event.dart
│   │   │   │   │   │   │   ├── orders_state.dart
│   │   │   │   │   │   │   ├── order_track_bloc.dart
│   │   │   │   │   │   │   ├── order_track_event.dart
│   │   │   │   │   │   │   └── order_track_state.dart
│   │   │   │   │   │   ├── pages/
│   │   │   │   │   │   │   ├── orders_page.dart
│   │   │   │   │   │   │   ├── order_detail_page.dart
│   │   │   │   │   │   │   └── order_track_page.dart
│   │   │   │   │   │   └── widgets/
│   │   │   │   │   │       ├── order_card.dart
│   │   │   │   │   │       └── status_timeline.dart
│   │   │   │   │   └── order_injector.dart
│   │   │   │   │
│   │   │   │   ├── profile/
│   │   │   │   │   ├── data/
│   │   │   │   │   │   └── profile_repository.dart
│   │   │   │   │   ├── domain/
│   │   │   │   │   │   └── profile_repository_interface.dart
│   │   │   │   │   ├── presentation/
│   │   │   │   │   │   ├── bloc/
│   │   │   │   │   │   └── pages/
│   │   │   │   │   │       └── profile_page.dart
│   │   │   │   │   └── profile_injector.dart
│   │   │   │   │
│   │   │   │   └── notifications/
│   │   │   │       ├── data/
│   │   │   │       │   └── notification_repository.dart
│   │   │   │       ├── domain/
│   │   │   │       │   └── notification_repository_interface.dart
│   │   │   │       ├── presentation/
│   │   │   │       │   ├── bloc/
│   │   │   │       │   └── pages/
│   │   │   │       │       └── notifications_page.dart
│   │   │   │       └── notification_injector.dart
│   │   │   │
│   │   │   └── services/
│   │   │       ├── websocket_service.dart      # Socket.IO client
│   │   │       ├── location_service.dart       # Geolocator
│   │   │       ├── map_service.dart            # Google Maps
│   │   │       ├── payment_service.dart        # Stripe SDK
│   │   │       └── notification_service.dart   # Firebase
│   │   │
│   │   ├── pubspec.yaml
│   │   └── test/
│   │       ├── unit/
│   │       ├── widget/
│   │       └── integration/
│   │
│   └── merchant_app/              # Merchant-facing app
│       ├── lib/
│       │   ├── main.dart
│       │   ├── core/
│       │   │   └── ...  # Shared structure with customer_app
│       │   ├── features/
│       │   │   ├── auth/
│       │   │   ├── dashboard/
│       │   │   │   ├── data/
│       │   │   │   ├── domain/
│       │   │   │   └── presentation/
│       │   │   │       ├── bloc/
│       │   │   │       ├── pages/
│       │   │   │       │   ├── dashboard_page.dart
│       │   │   │       │   └── sales_report_page.dart
│       │   │   │       └── widgets/
│       │   │   │           ├── metric_card.dart
│       │   │   │           └── hourly_chart.dart
│       │   │   ├── offers/
│       │   │   │   ├── data/
│       │   │   │   │   └── merchant_offers_repository.dart
│       │   │   │   ├── domain/
│       │   │   │   │   └── merchant_offers_repository_interface.dart
│       │   │   │   └── presentation/
│       │   │   │       ├── bloc/
│       │   │   │       │   ├── merchant_offers_bloc.dart
│       │   │   │       │   ├── merchant_offers_event.dart
│       │   │   │       │   └── merchant_offers_state.dart
│       │   │   │       ├── pages/
│       │   │   │       │   ├── offers_list_page.dart
│       │   │   │       │   ├── create_offer_page.dart
│       │   │   │       │   └── offer_detail_page.dart
│       │   │   │       └── widgets/
│       │   │   │           ├── offer_form.dart
│       │   │   │           ├── stock_editor.dart
│       │   │   │           └── offer_status_badge.dart
│       │   │   ├── orders/
│       │   │   │   ├── data/
│       │   │   │   ├── domain/
│       │   │   │   └── presentation/
│       │   │   │       ├── bloc/
│       │   │   │       ├── pages/
│       │   │   │       │   ├── incoming_orders_page.dart
│       │   │   │       │   └── order_detail_page.dart
│       │   │   │       └── widgets/
│       │   │   │           ├── order_item_card.dart
│       │   │   │           └── status_actions.dart
│       │   │   ├── products/
│       │   │   │   ├── data/
│       │   │   │   ├── domain/
│       │   │   │   └── presentation/
│       │   │   │       ├── bloc/
│       │   │   │       ├── pages/
│       │   │   │       │   ├── products_page.dart
│       │   │   │       │   └── add_product_page.dart
│       │   │   │       └── widgets/
│       │   │   │           └── product_tile.dart
│       │   │   └── settings/
│       │   │       ├── data/
│       │   │       ├── domain/
│       │   │       └── presentation/
│       │   │           └── pages/
│       │   │               ├── store_settings_page.dart
│       │   │               └── business_hours_page.dart
│       │   └── services/
│       │       ├── websocket_service.dart
│       │       └── notification_service.dart
│       └── test/
│
├── shared/                        # Shared package
│   ├── lib/
│   │   ├── models/
│   │   │   ├── offer.dart
│   │   │   ├── store.dart
│   │   │   ├── order.dart
│   │   │   └── user.dart
│   │   ├── enums/
│   │   │   ├── order_status.dart
│   │   │   └── user_role.dart
│   │   ├── helpers/
│   │   │   ├── date_formatter.dart
│   │   │   ├── price_formatter.dart
│   │   │   └── distance_formatter.dart
│   │   └── constants/
│   │       └── api_constants.dart
│   └── pubspec.yaml
│
└── docker-compose.yaml            # Local dev: Flutter + emulator
```

## State Management Strategy (BLoC)

### Why BLoC over Riverpod
- **Predictable** — explicit events/states make async flows debuggable
- **Testable** — pure Bloc classes with no widget dependency
- **Team-scale** — enforced separation of concerns at scale
- **Real-time ready** — WebSocket events map naturally to Bloc events

### Data Flow Pattern
```
┌──────────┐   Event    ┌──────────┐   State   ┌──────────┐
│  Widget  │───────────►│   BLoC   │──────────►│  Widget  │
│ (UI)     │            │ (Logic)  │           │ (Rebuild)│
└──────────┘            └────┬─────┘           └──────────┘
                             │
                    ┌────────┴────────┐
                    │   Repository    │
                    │  (Data layer)   │
                    └──┬──────────┬───┘
                       │          │
               ┌───────┘          └───────┐
               ▼                          ▼
        ┌──────────┐             ┌──────────────┐
        │ API Dio  │             │ WebSocket    │
        │ (REST)   │             │ (Socket.IO)  │
        └──────────┘             └──────────────┘
```

### Real-Time Stock Updates
```dart
// In OffersBloc
class OffersBloc extends Bloc<OffersEvent, OffersState> {
  final WebSocketService _ws;
  StreamSubscription? _subscription;

  void _onSubscribeToOffers() {
    _subscription?.cancel();
    _subscription = _ws.offerStream.listen((update) {
      add(StockUpdated(update.offerId, update.remaining));
    });
  }

  StreamSubscription<OrderStatusEvent> _subscribeToOrder(String orderId) {
    return _ws.orderStream(orderId).listen((status) {
      add(OrderStatusChanged(orderId, status));
    });
  }
}
```

### Key BLoC Instances
| BLoC                    | Responsibility                              | Events                                  |
|-------------------------|---------------------------------------------|-----------------------------------------|
| `AuthBloc`             | Login, register, token refresh              | `LoginRequested`, `TokenExpired`        |
| `OffersBloc`           | Nearby offers feed, real-time stock updates | `FetchNearbyOffers`, `StockUpdated`     |
| `MapBloc`              | Map markers, region changes                 | `MapMoved`, `MarkerTapped`             |
| `OfferDetailBloc`      | Single offer detail + countdown timer       | `LoadOffer`, `StockChanged`            |
| `OrdersBloc`           | Order history, pagination                   | `FetchOrders`, `CancelOrder`           |
| `OrderTrackBloc`       | Real-time order status tracking             | `TrackOrder`, `StatusUpdated`          |
| `MerchantOffersBloc`   | Merchant CRUD + stock management            | `CreateOffer`, `UpdateStock`           |
| `IncomingOrdersBloc`   | Merchant incoming orders (real-time)        | `NewOrder`, `AcceptOrder`              |

### Dependency Injection (GetIt)
```dart
// injector.dart — service locator setup
final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<Dio>(() => createDio());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));

  // Services
  sl.registerSingletonAsync<WebSocketService>(() async =>
    WebSocketService.connect(apiConfig.wsUrl));
  sl.registerSingleton<LocationService>(LocationService());
  sl.registerSingleton<MapService>(MapService());

  // Auth
  sl.registerFactory<AuthBloc>(() => AuthBloc(
    authRepository: sl(),
    tokenStorage: sl(),
  ));

  // Offers
  sl.registerFactory<OffersBloc>(() => OffersBloc(
    offersRepository: sl(),
    webSocket: sl(),
  ));

  // Orders
  sl.registerFactory<OrdersBloc>(() => OrdersBloc(
    orderRepository: sl(),
  ));
}
```
