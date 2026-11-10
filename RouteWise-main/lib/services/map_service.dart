import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/location.dart';
import 'maps_service.dart';

class MapService {
	static Set<Marker> buildMarkers(
		Location home,
		List<Location> stops, {
		String? activeStopId,
		LatLng? currentPosition,
	}) {
		return MapsService.buildMarkers(
			home,
			stops,
			activeStopId: activeStopId,
			currentPosition: currentPosition,
		);
	}

	static Set<Polyline> buildRoutePolylines(Location home, List<Location> optimizedStops) {
		return MapsService.buildRoutePolylines(home, optimizedStops);
	}

	static LatLngBounds computeBounds(Location home, List<Location> stops) {
		return MapsService.computeBounds(home, stops);
	}
}
