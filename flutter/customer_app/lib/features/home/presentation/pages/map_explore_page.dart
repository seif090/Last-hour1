import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../bloc/offers_bloc.dart';
import '../../../../services/map_service.dart';
import '../../../../services/location_service.dart';
import '../../../../injector.dart';
import 'package:lasthour_shared/models/offer.dart';

class MapExplorePage extends StatefulWidget {
  final double? focusLat;
  final double? focusLng;

  const MapExplorePage({super.key, this.focusLat, this.focusLng});

  @override
  State<MapExplorePage> createState() => _MapExplorePageState();
}

class _MapExplorePageState extends State<MapExplorePage> {
  final _mapService = sl<MapService>();
  final _locationService = sl<LocationService>();
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  String? _selectedCategory;
  List<Offer> _allOffers = [];

  static const _categories = ['Food', 'Drinks', 'Electronics', 'Fashion', 'Other'];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
      });
      if (_mapController != null && widget.focusLat != null && widget.focusLng != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(widget.focusLat!, widget.focusLng!), 16,
        ));
      }
    } catch (_) {
      if (widget.focusLat != null && widget.focusLng != null) {
        setState(() {
          _currentPosition = LatLng(widget.focusLat!, widget.focusLng!);
        });
      }
    }
  }

  void _onOffersLoaded(List<Offer> offers) {
    _allOffers = offers;
    _rebuildMarkers();
  }

  void _rebuildMarkers() {
    final filtered = _selectedCategory != null
        ? _allOffers.where((o) => o.category == _selectedCategory).toList()
        : _allOffers;
    _markers = _mapService.buildOfferMarkers(filtered, onTap: (id) => context.go('/offers/$id'));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Center on me',
            onPressed: _centerOnMe,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh offers',
            onPressed: () => context.read<OffersBloc>().add(FetchOffers()),
          ),
        ],
      ),
      body: BlocBuilder<OffersBloc, OffersState>(
        builder: (context, state) {
          if (state is OffersLoaded && _currentPosition != null) {
            if (_allOffers.isEmpty || !_allOffers.every((o) => state.offers.contains(o))) {
              _onOffersLoaded(state.offers);
            }
          }

          if (_currentPosition == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildCategoryFilter(),
              Expanded(child: _buildMap()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final theme = Theme.of(context);
    final categoryColors = {
      'Food': theme.colorScheme.error,
      'Drinks': theme.colorScheme.primary,
      'Electronics': theme.colorScheme.tertiary,
      'Fashion': theme.colorScheme.primary,
      'Other': theme.colorScheme.tertiary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _selectedCategory == null,
            onSelected: (_) => setState(() { _selectedCategory = null; _rebuildMarkers(); }),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  selectedColor: categoryColors[cat]?.withValues(alpha: 0.2),
                  onSelected: (_) {
                    setState(() => _selectedCategory = selected ? null : cat);
                    _rebuildMarkers();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentPosition!,
        zoom: 14,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        if (widget.focusLat != null && widget.focusLng != null) {
          controller.animateCamera(CameraUpdate.newLatLngZoom(
            LatLng(widget.focusLat!, widget.focusLng!), 16,
          ));
        }
      },
    );
  }

  void _centerOnMe() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      await _mapController?.animateCamera(CameraUpdate.newLatLng(
        LatLng(pos.latitude, pos.longitude),
      ));
    } catch (_) {}
  }
}
