import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationTrackerService {
  StreamSubscription<Position>? _positionSubscription;
  final _positionController = StreamController<Position>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<Position> get positionStream => _positionController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isTracking => _positionSubscription != null;

  Future<bool> checkAndRequestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorController.add('GPS_DISABLED');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorController.add('PERMISSION_DENIED');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _errorController.add('PERMISSION_PERMANENTLY_DENIED');
      return false;
    }

    return true;
  }

  void startTracking({
    required String accuracyLevel,
    int timeIntervalSeconds = 3,
    int distanceFilterMeters = 5,
  }) async {
    if (_positionSubscription != null) return;

    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return;

    LocationAccuracy accuracy;
    switch (accuracyLevel) {
      case 'low':
        accuracy = LocationAccuracy.low;
        break;
      case 'medium':
        accuracy = LocationAccuracy.medium;
        break;
      case 'high':
      default:
        accuracy = LocationAccuracy.high;
        break;
    }

    final locationSettings = kIsWeb
        ? AndroidSettings(
            accuracy: accuracy,
            distanceFilter: distanceFilterMeters,
            intervalDuration: Duration(seconds: timeIntervalSeconds),
          )
        : LocationSettings(
            accuracy: accuracy,
            distanceFilter: distanceFilterMeters,
          );

    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _positionController.add(position);
        },
        onError: (error) {
          if (kDebugMode) {
            debugPrint('[LocationTrackerService] Error in stream: $error');
          }
          if (error is TimeoutException) {
            _errorController.add('LOCATION_TIMEOUT');
          } else {
            _errorController.add(error.toString());
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocationTrackerService] startTracking exception: $e');
      }
      _errorController.add(e.toString());
    }
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    stopTracking();
    _positionController.close();
    _errorController.close();
  }
}
