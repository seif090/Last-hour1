import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lasthour_shared/models/offer.dart';

class MapService {
  Set<Marker> buildOfferMarkers(List<Offer> offers, {void Function(String)? onTap}) {
    return offers.map((o) {
      final hue = _categoryToHue(o.category);
      return Marker(
        markerId: MarkerId(o.id),
        position: LatLng(o.lat, o.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: o.storeName,
          snippet: '${o.title} — ${o.discountedPrice.toStringAsFixed(2)} EGP',
          onTap: onTap != null ? () => onTap(o.id) : null,
        ),
      );
    }).toSet();
  }

  double _categoryToHue(String? category) {
    switch (category?.toLowerCase()) {
      case 'food': return BitmapDescriptor.hueRed;
      case 'drinks': return BitmapDescriptor.hueAzure;
      case 'electronics': return BitmapDescriptor.hueViolet;
      case 'fashion': return BitmapDescriptor.hueRose;
      default: return BitmapDescriptor.hueGreen;
    }
  }

  LatLngBounds boundsFromOffers(List<Offer> offers, {LatLng? center}) {
    if (offers.isEmpty && center != null) {
      return LatLngBounds(southwest: center, northeast: center);
    }

    double south = 90, west = 180, north = -90, east = -180;
    for (final o in offers) {
      if (o.lat < south) south = o.lat;
      if (o.lat > north) north = o.lat;
      if (o.lng < west) west = o.lng;
      if (o.lng > east) east = o.lng;
    }

    if (center != null) {
      south = south < center.latitude ? south : center.latitude;
      north = north > center.latitude ? north : center.latitude;
      west = west < center.longitude ? west : center.longitude;
      east = east > center.longitude ? east : center.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south - 0.01, west - 0.01),
      northeast: LatLng(north + 0.01, east + 0.01),
    );
  }
}
