import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  GoogleMapController? _mapController;

  void setController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> animateToLocation(LatLng position, {double zoom = 14}) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: zoom),
      ),
    );
  }

  Future<void> fitBounds(LatLngBounds bounds, {int padding = 100}) async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  Set<Marker> buildStoreMarkers(
    List<Map<String, dynamic>> stores,
    void Function(String storeId) onTap,
  ) {
    final markers = <Marker>{};

    for (final store in stores) {
      final id = store['id'] as String;
      final name = store['name'] as String;
      final lat = store['lat'] as double;
      final lng = store['lng'] as double;
      final distance = store['distance_m'] as double?;

      markers.add(
        Marker(
          markerId: MarkerId('store_$id'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: name,
            snippet: distance != null
                ? '${(distance / 1000).toStringAsFixed(1)} km away'
                : null,
          ),
          onTap: () => onTap(id),
        ),
      );
    }

    return markers;
  }

  Set<Marker> buildOfferMarkers(
    List<OfferMapItem> offers,
    void Function(String offerId) onTap,
  ) {
    final markers = <Marker>{};

    for (final offer in offers) {
      markers.add(
        Marker(
          markerId: MarkerId('offer_${offer.id}'),
          position: LatLng(offer.lat, offer.lng),
          icon: _buildDiscountMarker(offer.discountPercent),
          infoWindow: InfoWindow(
            title: offer.title,
            snippet: '${offer.discountedPrice} EGP (${offer.discountPercent.toStringAsFixed(0)}% off)',
          ),
          onTap: () => onTap(offer.id),
        ),
      );
    }

    return markers;
  }

  BitmapDescriptor _buildDiscountMarker(double percent) {
    // In production: generate custom marker images with discount badge
    return BitmapDescriptor.defaultMarkerWithHue(
      percent > 50 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
    );
  }

  void dispose() {
    _mapController?.dispose();
  }
}

class OfferMapItem {
  final String id;
  final String title;
  final double discountedPrice;
  final double originalPrice;
  final double lat;
  final double lng;

  double get discountPercent =>
      ((originalPrice - discountedPrice) / originalPrice * 100);

  OfferMapItem({
    required this.id,
    required this.title,
    required this.discountedPrice,
    required this.originalPrice,
    required this.lat,
    required this.lng,
  });
}
