import 'package:geolocator/geolocator.dart';
import '../models/location.dart';

class ArrivalService {
  double _radius;
  String? _lastArrivalTriggeredStopId;

  ArrivalService({double defaultRadius = 50.0}) : _radius = defaultRadius;

  void updateRadius(double radius) {
    _radius = radius;
  }

  void resetForNewStop() {
    _lastArrivalTriggeredStopId = null;
  }

  bool checkArrival({
    required Position currentPosition,
    required Location destination,
    required Function(double distance) onArrived,
  }) {
    // If we've already triggered for this stop, do not trigger again
    if (_lastArrivalTriggeredStopId == destination.id) return false;

    final distance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      destination.latitude,
      destination.longitude,
    );

    if (distance <= _radius) {
      _lastArrivalTriggeredStopId = destination.id;
      onArrived(distance);
      return true;
    }

    return false;
  }
}
