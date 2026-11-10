import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/location.dart';

class MapsService {
  static Set<Marker> buildMarkers(
    Location home,
    List<Location> stops, {
    String? activeStopId,
    LatLng? currentPosition,
  }) {
    final markers = <Marker>{};

    markers.add(
      Marker(
        markerId: const MarkerId('home'),
        position: LatLng(home.latitude, home.longitude),
        infoWindow: InfoWindow(title: home.name, snippet: 'Home Base'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    if (currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_position'),
          position: currentPosition,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          zIndex: 10,
        ),
      );
    }

    for (final stop in stops) {
      double hue;
      String titleSuffix = '';
      if (stop.visited) {
        hue = BitmapDescriptor.hueGreen;
      } else if (stop.id == activeStopId) {
        hue = BitmapDescriptor.hueOrange;
        titleSuffix = ' (Active Stop)';
      } else {
        hue = BitmapDescriptor.hueBlue;
      }

      markers.add(
        Marker(
          markerId: MarkerId(stop.id),
          position: LatLng(stop.latitude, stop.longitude),
          infoWindow: InfoWindow(title: '${stop.name}$titleSuffix'),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        ),
      );
    }

    return markers;
  }

  static Set<Polyline> buildRoutePolylines(Location home, List<Location> optimizedStops) {
    final points = <LatLng>[
      LatLng(home.latitude, home.longitude),
      ...optimizedStops.map((stop) => LatLng(stop.latitude, stop.longitude)),
      LatLng(home.latitude, home.longitude),
    ];

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: Colors.blueAccent,
        width: 4,
      ),
    };
  }

  static LatLngBounds computeBounds(Location home, List<Location> stops) {
    final points = <LatLng>[
      LatLng(home.latitude, home.longitude),
      ...stops.map((stop) => LatLng(stop.latitude, stop.longitude)),
    ];

    double south = points.first.latitude;
    double north = points.first.latitude;
    double west = points.first.longitude;
    double east = points.first.longitude;

    for (final point in points) {
      if (point.latitude < south) south = point.latitude;
      if (point.latitude > north) north = point.latitude;
      if (point.longitude < west) west = point.longitude;
      if (point.longitude > east) east = point.longitude;
    }

    if ((north - south).abs() < 1e-6) {
      north += 0.001;
      south -= 0.001;
    }
    if ((east - west).abs() < 1e-6) {
      east += 0.001;
      west -= 0.001;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }
}