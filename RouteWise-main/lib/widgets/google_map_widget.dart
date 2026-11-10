import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/map_service.dart';
import '../services/route_provider.dart';

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({super.key});

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _controller;
  final Completer<GoogleMapController> _controllerCompleter = Completer();

  @override
  void dispose() {
    // On web, disposing the GoogleMap controller can trigger an assertion
    // inside `google_maps_flutter_web` when the underlying map isn't
    // available yet ("Maps cannot be retrieved before calling buildView!").
    // Skip explicit dispose on web to avoid that crash; the engine will
    // clean up platform resources when the widget tree is torn down.
    if (!kIsWeb) {
      _controller?.dispose();
    }
    super.dispose();
  }

  Future<void> _moveCameraToBounds(LatLngBounds bounds) async {
    if (_controller == null) return;
    try {
      await _controller!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (_) {
      // On web the camera update may fail if map not rendered yet; try a basic move.
      final center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
      await _controller!.animateCamera(CameraUpdate.newLatLngZoom(center, 12));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteProvider>(
      builder: (context, provider, child) {
        final home = provider.home;
        final stops = provider.stops;
        final currentLatLng = provider.currentPosition != null
            ? LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude)
            : null;
        final markers = MapService.buildMarkers(
          home,
          stops,
          activeStopId: provider.journeyState.isJourneyActive && provider.journeyState.currentDestination != null
              ? provider.journeyState.currentDestination!.id
              : null,
          currentPosition: currentLatLng,
        );
        final polylines = provider.routePolylines;
        final bounds = MapService.computeBounds(home, stops);

        // When controller is ready, animate to bounds or center on user.
        if (_controllerCompleter.isCompleted && _controller != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.journeyState.isJourneyActive &&
                provider.journeySettings.autoCenterMap &&
                currentLatLng != null) {
              _controller!.animateCamera(CameraUpdate.newLatLng(currentLatLng));
            } else {
              _moveCameraToBounds(bounds);
            }
          });
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(home.latitude, home.longitude),
                zoom: 10,
              ),
              onMapCreated: (controller) {
                if (!_controllerCompleter.isCompleted) {
                  _controllerCompleter.complete(controller);
                }
                _controller = controller;
                WidgetsBinding.instance.addPostFrameCallback((_) => _moveCameraToBounds(bounds));
              },
              myLocationEnabled: false,
              markers: markers,
              polylines: polylines,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              compassEnabled: true,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),
            if (provider.routeError != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Directions API Failed',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (provider.isRouting)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text('Loading route...', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
