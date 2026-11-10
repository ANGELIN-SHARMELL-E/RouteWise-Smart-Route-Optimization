import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/location.dart';
import '../models/route_snapshot.dart';
import '../models/journey_state.dart';
import '../models/journey_settings.dart';
import 'directions_service.dart';
import 'location_service.dart';
import 'maps_service.dart';
import 'storage_service.dart';
import 'journey_service.dart';
import 'voice_guidance_service.dart';
import 'location_tracker_service.dart';
import 'arrival_service.dart';

class RouteProvider extends ChangeNotifier {
  RouteProvider()
      : _locationService = LocationService(),
        _directionsService = DirectionsService() {
    _bootstrap();
  }

  final LocationService _locationService;
  final DirectionsService _directionsService;
  final LocationTrackerService _locationTrackerService = LocationTrackerService();
  final ArrivalService _arrivalService = ArrivalService();
  final VoiceGuidanceService _voiceGuidanceService = VoiceGuidanceService();

  StreamSubscription<Position>? _trackerSubscription;
  StreamSubscription<String>? _trackerErrorSubscription;

  static final Location _fallbackHome = Location(
    id: 'unset_home',
    name: 'Set Home Location',
    latitude: 0,
    longitude: 0,
  );

  Location _home = _fallbackHome;
  final List<Location> _stops = [];
  bool _isOptimized = false;
  bool _isDarkMode = false;
  bool _isRouting = false;
  bool _usingDirections = false;
  bool _initialized = false;
  String _routeApiStatus = 'UNKNOWN';
  int _routePointCount = 0;
  int _routeDistanceMeters = 0;
  int _goingDistanceMeters = 0;
  int _returnDistanceMeters = 0;
  int _routeDurationSeconds = 0;
  String? _routeError;
  Set<Polyline> _routePolylines = {};
  List<RouteSegmentInfo> _routeSegmentInfo = [];
  JourneyState _journeyState = const JourneyState();

  JourneySettings _journeySettings = const JourneySettings();
  Position? _currentPosition;
  double _liveSpeed = 0.0;
  double _gpsAccuracy = 0.0;
  double _distanceToDestination = 0.0;
  DateTime? _estimatedArrivalTime;
  bool _hasArrivedAtDestination = false;
  String? _locationTrackerError;

  JourneySettings get journeySettings => _journeySettings;
  Position? get currentPosition => _currentPosition;
  double get liveSpeed => _liveSpeed;
  double get gpsAccuracy => _gpsAccuracy;
  double get distanceToDestination => _distanceToDestination;
  DateTime? get estimatedArrivalTime => _estimatedArrivalTime;
  bool get hasArrivedAtDestination => _hasArrivedAtDestination;
  String? get locationTrackerError => _locationTrackerError;

  Location get home => _home;
  List<Location> get stops => List.unmodifiable(_stops);
  bool get isOptimized => _isOptimized;
  bool get isDarkMode => _isDarkMode;
  bool get isRouting => _isRouting;
  bool get usingDirections => _usingDirections;
  bool get isInitialized => _initialized;
  String get routeApiStatus => _routeApiStatus;
  int get routePointCount => _routePointCount;
  JourneyState get journeyState => _journeyState;
  String get routeSourceLabel {
    if (_routeError != null) return 'Directions API Failed';
    if (_usingDirections) return 'Directions API Active';
    if (_isRouting) return 'Loading Directions API...';
    return 'No active route';
  }

  double get routeDistanceKm => _routeDistanceMeters / 1000.0;

  double get goingDistanceKm {
    if (_stops.isEmpty) return 0.0;
    if (_usingDirections) {
      return _goingDistanceMeters / 1000.0;
    }
    var totalDistance = 0.0;
    var current = _home;
    for (final stop in _stops) {
      totalDistance += _distanceBetween(
        current.latitude,
        current.longitude,
        stop.latitude,
        stop.longitude,
      );
      current = stop;
    }
    return totalDistance;
  }

  double get returnDistanceKm {
    if (_stops.isEmpty) return 0.0;
    if (_usingDirections) {
      return _returnDistanceMeters / 1000.0;
    }
    final lastStop = _stops.last;
    return _distanceBetween(
      lastStop.latitude,
      lastStop.longitude,
      _home.latitude,
      _home.longitude,
    );
  }

  Duration get routeDuration => Duration(seconds: _routeDurationSeconds);
  String? get routeError => _routeError;
  Set<Polyline> get routePolylines => Set.unmodifiable(_routePolylines);
  List<RouteSegmentInfo> get routeSegmentInfo => List.unmodifiable(_routeSegmentInfo);
  bool get routeGeometryWarning => _routeSegmentInfo.any((info) => info.pointCount < 10);
  List<Location> get activeRoute => List.unmodifiable(_stops);

  double get totalDistance {
    if (_routeDistanceMeters > 0) {
      return _routeDistanceMeters / 1000.0;
    }
    return _stops.isEmpty ? 0.0 : _estimateDistance();
  }

  Future<void> _bootstrap() async {
    await StorageService.initialize();

    final savedHome = await StorageService.loadHome();
    final savedStops = await StorageService.loadStops();
    final savedRoute = await StorageService.loadRouteSnapshot();

    if (savedHome != null) {
      _home = savedHome;
    }
    _stops
      ..clear()
      ..addAll(savedStops);

    if (savedRoute != null) {
      _home = savedRoute.home;
      _stops
        ..clear()
        ..addAll(savedRoute.stops);
      _isOptimized = savedRoute.isOptimized;
      _routeApiStatus = savedRoute.routeApiStatus ?? 'UNKNOWN';
      _routePointCount = savedRoute.routePointCount;
      _routeDistanceMeters = savedRoute.routeDistanceMeters;
      _goingDistanceMeters = savedRoute.goingDistanceMeters;
      _returnDistanceMeters = savedRoute.returnDistanceMeters;
      _routeDurationSeconds = savedRoute.routeDurationSeconds;
    }

    _initialized = true;

    final savedSettings = await StorageService.loadJourneySettings();
    if (savedSettings != null) {
      _journeySettings = JourneySettings.fromMap(savedSettings);
    }
    _arrivalService.updateRadius(_journeySettings.arrivalRadius);
    _voiceGuidanceService.updateSettings(enabled: _journeySettings.voiceGuidance);
    
    await JourneyService.initialize();
    final savedJourney = await JourneyService.loadJourneyState();
    if (savedJourney != null) {
      _journeyState = savedJourney;
      if (_journeyState.isJourneyActive) {
        _startLocationTracking();
      }
    }

    notifyListeners();

    if (savedHome == null && savedRoute == null && _stops.isEmpty) {
      final permissionGranted = await _locationService.requestLocationPermission();
      if (permissionGranted) {
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          final homeLocation = await _locationService.reverseGeocode(
            position.latitude,
            position.longitude,
          );
          if (homeLocation != null) {
            _home = homeLocation.copyWith(id: 'home_current');
            await _persistState();
            notifyListeners();
            return;
          }
        }
      }
    }

    if (savedRoute != null && _stops.isNotEmpty) {
      await _refreshDirections();
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Future<void> updateHome(Location newHome) async {
    _home = newHome;
    _isOptimized = false;
    _routeError = null;
    await _persistState();
    notifyListeners();
    await _refreshDirections();
  }

  Future<bool> setHomeToCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        return false;
      }

      final homeLocation = await _locationService.reverseGeocode(
        position.latitude,
        position.longitude,
      );
      if (homeLocation == null) {
        return false;
      }

      await updateHome(homeLocation.copyWith(id: 'home_current'));
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[RouteProvider] current location error: $error');
      }
      return false;
    }
  }

  Future<void> addStop(Location stop) async {
    if (_stops.any((existing) => existing.id == stop.id)) return;
    _stops.add(stop);
    _isOptimized = false;
    _routeError = null;
    await _persistState();
    notifyListeners();
    await _refreshDirections();
  }

  Future<void> removeStop(String id) async {
    _stops.removeWhere((stop) => stop.id == id);
    _isOptimized = false;
    _routeError = null;
    await _persistState();
    notifyListeners();
    await _refreshDirections();
  }

  Future<void> toggleVisited(String id) async {
    final index = _stops.indexWhere((stop) => stop.id == id);
    if (index == -1) return;

    _stops[index] = _stops[index].copyWith(
      visited: !_stops[index].visited,
    );
    await _persistState();
    notifyListeners();
    await _refreshDirections();
  }

  Future<void> reorderStops(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = _stops.removeAt(oldIndex);
    _stops.insert(newIndex, item);
    _isOptimized = false;
    await _persistState();
    notifyListeners();
    await _refreshDirections();
  }

  Future<void> optimizeRoute() async {
    if (_stops.isEmpty) return;

    final optimized = _optimizeRoute(_home, _stops);
    _stops
      ..clear()
      ..addAll(optimized);
    _isOptimized = true;
    await _persistState();
    notifyListeners();
    await _refreshDirections();
  }

  Future<void> clearStops() async {
    _stops.clear();
    _isOptimized = false;
    _routePolylines = {};
    _routeSegmentInfo = [];
    _routeDistanceMeters = 0;
    _goingDistanceMeters = 0;
    _returnDistanceMeters = 0;
    _routeDurationSeconds = 0;
    _routeError = null;
    _journeyState = const JourneyState();
    await Future.wait([
      StorageService.clearRoute(),
      JourneyService.clearJourneyState(),
    ]);
    notifyListeners();
  }

  Future<void> _persistState() async {
    await Future.wait([
      StorageService.saveHome(_home),
      StorageService.saveStops(_stops),
      StorageService.saveRouteSnapshot(
        RouteSnapshot(
          home: _home,
          stops: _stops,
          isOptimized: _isOptimized,
          routeApiStatus: _routeApiStatus,
          routePointCount: _routePointCount,
          routeDistanceMeters: _routeDistanceMeters,
          goingDistanceMeters: _goingDistanceMeters,
          returnDistanceMeters: _returnDistanceMeters,
          routeDurationSeconds: _routeDurationSeconds,
        ),
      ),
      JourneyService.saveJourneyState(_journeyState),
    ]);
  }

  Future<void> _refreshDirections() async {
    if (_stops.isEmpty) {
      _usingDirections = false;
      _routeApiStatus = 'EMPTY';
      _routePointCount = 0;
      _routePolylines = {};
      _routeSegmentInfo = [];
      _routeDistanceMeters = 0;
      _goingDistanceMeters = 0;
      _returnDistanceMeters = 0;
      _routeDurationSeconds = 0;
      _routeError = null;
      await _persistState();
      notifyListeners();
      return;
    }

    _isRouting = true;
    _usingDirections = false;
    _routeError = null;
    notifyListeners();

    try {
      final segmentPoints = [_home, ..._stops, _home];
      final newPolylines = <Polyline>[];
      final newSegmentInfo = <RouteSegmentInfo>[];
      var totalDistance = 0;
      var goingDistance = 0;
      var returnDistance = 0;
      var totalDuration = 0;
      var totalPointCount = 0;

      for (var i = 0; i < segmentPoints.length - 1; i++) {
        final origin = segmentPoints[i];
        final destination = segmentPoints[i + 1];
        final directions = await _directionsService.requestDirections(origin, destination);

        if (!directions.success) {
          _routeError = directions.errorMessage ?? _friendlyDirectionsError(directions.apiStatus);
          _routeApiStatus = directions.apiStatus;
          break;
        }

        totalDistance += directions.distanceMeters;
        totalDuration += directions.durationSeconds;
        totalPointCount += directions.points.length;

        if (i == segmentPoints.length - 2) {
          returnDistance = directions.distanceMeters;
        } else {
          goingDistance += directions.distanceMeters;
        }

        final polyline = Polyline(
          polylineId: PolylineId('segment_$i'),
          points: directions.points,
          color: Colors.blueAccent,
          width: 5,
        );

        newPolylines.add(polyline);
        newSegmentInfo.add(RouteSegmentInfo(
          segmentIndex: i,
          pointCount: polyline.points.length,
          firstPoint: directions.points.first,
          secondPoint: directions.points.length > 1 ? directions.points[1] : null,
          lastPoint: directions.points.last,
          sourceType: directions.points.length <= 2 ? 'origin/destination only' : 'road geometry',
        ));
      }

      if (_routeError == null && newPolylines.isNotEmpty) {
        _usingDirections = true;
        _routePolylines = newPolylines.toSet();
        _routeSegmentInfo = newSegmentInfo;
        _routeDistanceMeters = totalDistance;
        _goingDistanceMeters = goingDistance;
        _returnDistanceMeters = returnDistance;
        _routeDurationSeconds = totalDuration;
        _routePointCount = totalPointCount;
        _routeApiStatus = 'OK';
      } else {
        _usingDirections = false;
        _routePolylines = {};
        _routeSegmentInfo = [];
        _routePointCount = 0;
        _goingDistanceMeters = 0;
        _returnDistanceMeters = 0;
      }

      await _persistState();
    } catch (error) {
      _routeError = 'Unable to load directions.';
      _usingDirections = false;
      _routeApiStatus = 'ERROR';
      _routePointCount = 0;
      _routeSegmentInfo = [];
      _routePolylines = {};
      if (kDebugMode) {
        debugPrint('[RouteProvider] Exception refreshing directions: $error');
      }
    } finally {
      _isRouting = false;
      notifyListeners();
    }
  }

  String _friendlyDirectionsError(String status) {
    if (status == 'ZERO_RESULTS') {
      return 'No driving route was found for this trip.';
    }
    return 'Unable to load directions right now.';
  }

  double _estimateDistance() {
    var totalDistance = 0.0;
    var current = _home;
    for (final stop in _stops) {
      totalDistance += _distanceBetween(
        current.latitude,
        current.longitude,
        stop.latitude,
        stop.longitude,
      );
      current = stop;
    }
    totalDistance += _distanceBetween(
      current.latitude,
      current.longitude,
      _home.latitude,
      _home.longitude,
    );
    return totalDistance;
  }

  List<Location> _optimizeRoute(Location home, List<Location> destinations) {
    if (destinations.length <= 1) {
      return List<Location>.from(destinations);
    }

    final unvisited = List<Location>.from(destinations);
    final optimizedRoute = <Location>[];
    var current = home;

    while (unvisited.isNotEmpty) {
      var nearest = unvisited.first;
      var minDistance = double.infinity;
      var nearestIndex = 0;

      for (var i = 0; i < unvisited.length; i++) {
        final distance = _distanceBetween(
          current.latitude,
          current.longitude,
          unvisited[i].latitude,
          unvisited[i].longitude,
        );
        if (distance < minDistance) {
          minDistance = distance;
          nearest = unvisited[i];
          nearestIndex = i;
        }
      }

      optimizedRoute.add(nearest);
      current = nearest;
      unvisited.removeAt(nearestIndex);
    }

    return optimizedRoute;
  }

  double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (sin(dLon / 2) * sin(dLon / 2) * cos(lat1Rad) * cos(lat2Rad));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180.0;

  Future<void> startJourney() async {
    if (_home.id == 'unset_home' || _stops.isEmpty || !_isOptimized) return;

    // Reset visited flag on stops to make sure they are fresh
    for (var i = 0; i < _stops.length; i++) {
      _stops[i] = _stops[i].copyWith(visited: false);
    }

    _journeyState = JourneyState(
      isJourneyActive: true,
      currentStopIndex: 0,
      currentDestination: _stops[0],
      completedStops: const [],
      remainingStops: List<Location>.from(_stops),
      journeyStartTime: DateTime.now(),
      totalDistance: 0.0,
      estimatedRemainingDistance: _calculateRemainingDistance(0),
    );

    _hasArrivedAtDestination = false;
    _arrivalService.resetForNewStop();
    _startLocationTracking();

    await _persistState();
    notifyListeners();
    await _refreshDirections();
  }

  Future<void> completeActiveStop() async {
    if (!_journeyState.isJourneyActive) return;
    
    final currentIndex = _journeyState.currentStopIndex;
    if (currentIndex < 0 || currentIndex >= _stops.length) return;

    // Mark current stop as visited
    final completedStop = _stops[currentIndex].copyWith(visited: true);
    _stops[currentIndex] = completedStop;

    final newCompletedStops = List<Location>.from(_journeyState.completedStops)..add(completedStop);
    final newRemainingStops = List<Location>.from(_journeyState.remainingStops)..removeAt(0);

    // Calculate distance traveled in this step
    final prevLocation = currentIndex == 0 ? _home : _stops[currentIndex - 1];
    final distanceStep = _distanceBetween(
      prevLocation.latitude,
      prevLocation.longitude,
      completedStop.latitude,
      completedStop.longitude,
    );

    final newTotalDistance = _journeyState.totalDistance + distanceStep;
    final nextIndex = currentIndex + 1;

    _hasArrivedAtDestination = false;
    _arrivalService.resetForNewStop();

    if (nextIndex < _stops.length) {
      _journeyState = _journeyState.copyWith(
        currentStopIndex: nextIndex,
        currentDestination: _stops[nextIndex],
        completedStops: newCompletedStops,
        remainingStops: newRemainingStops,
        totalDistance: newTotalDistance,
        estimatedRemainingDistance: _calculateRemainingDistance(nextIndex),
      );
    } else {
      // All stops completed! Now destination is back home.
      _journeyState = _journeyState.copyWith(
        currentStopIndex: nextIndex,
        currentDestination: _home,
        completedStops: newCompletedStops,
        remainingStops: newRemainingStops,
        totalDistance: newTotalDistance,
        estimatedRemainingDistance: _distanceBetween(
          completedStop.latitude,
          completedStop.longitude,
          _home.latitude,
          _home.longitude,
        ),
      );
      _stopLocationTracking();
    }

    await _persistState();
    notifyListeners();
    await _refreshDirections();
  }

  Future<void> skipActiveStop() async {
    if (!_journeyState.isJourneyActive || _stops.isEmpty) return;

    final currentIndex = _journeyState.currentStopIndex;
    if (currentIndex < 0 || currentIndex >= _stops.length) return;

    final skippedStop = _stops[currentIndex];
    final remainingStopsList = _stops.sublist(currentIndex);
    
    remainingStopsList.remove(skippedStop);
    
    final startLocation = _currentPosition != null
        ? Location(
            id: 'current_position_temp',
            name: 'Current Location',
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
          )
        : (currentIndex == 0 ? _home : _stops[currentIndex - 1]);
        
    final reoptimizedRemaining = _optimizeRoute(startLocation, remainingStopsList);
    reoptimizedRemaining.add(skippedStop);
    
    _stops.removeRange(currentIndex, _stops.length);
    _stops.addAll(reoptimizedRemaining);
    
    _hasArrivedAtDestination = false;
    _arrivalService.resetForNewStop();

    _journeyState = _journeyState.copyWith(
      currentDestination: _stops[currentIndex],
      remainingStops: List<Location>.from(_stops.sublist(currentIndex)),
      estimatedRemainingDistance: _calculateRemainingDistance(currentIndex),
    );
    
    await _persistState();
    notifyListeners();
    await _refreshDirections();
  }

  Future<void> cancelJourney() async {
    _journeyState = const JourneyState();
    for (var i = 0; i < _stops.length; i++) {
      _stops[i] = _stops[i].copyWith(visited: false);
    }
    _hasArrivedAtDestination = false;
    _stopLocationTracking();
    await _persistState();
    notifyListeners();
    await _refreshDirections();
  }

  void _startLocationTracking() {
    _trackerSubscription?.cancel();
    _trackerErrorSubscription?.cancel();

    _arrivalService.updateRadius(_journeySettings.arrivalRadius);
    _voiceGuidanceService.updateSettings(enabled: _journeySettings.voiceGuidance);

    if (_journeySettings.keepScreenAwake) {
      WakelockPlus.enable().catchError((_) {});
    } else {
      WakelockPlus.disable().catchError((_) {});
    }

    _locationTrackerService.startTracking(
      accuracyLevel: _journeySettings.locationAccuracy,
    );

    _trackerSubscription = _locationTrackerService.positionStream.listen((Position position) {
      _onLocationUpdated(position);
    });

    _trackerErrorSubscription = _locationTrackerService.errorStream.listen((String error) {
      _onLocationError(error);
    });
  }

  void _stopLocationTracking() {
    _trackerSubscription?.cancel();
    _trackerSubscription = null;
    _trackerErrorSubscription?.cancel();
    _trackerErrorSubscription = null;
    _locationTrackerService.stopTracking();
    _currentPosition = null;
    _liveSpeed = 0.0;
    _gpsAccuracy = 0.0;
    _estimatedArrivalTime = null;
    WakelockPlus.disable().catchError((_) {});
  }

  void _onLocationUpdated(Position position) {
    _currentPosition = position;
    _liveSpeed = position.speed * 3.6; // Convert m/s to km/h
    _gpsAccuracy = position.accuracy;

    final dest = _journeyState.currentDestination;
    if (dest != null) {
      // Calculate distance to current destination
      final dist = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        dest.latitude,
        dest.longitude,
      );
      _distanceToDestination = dist;

      // Calculate ETA
      final speed = position.speed > 0.5 ? position.speed : 8.33; // Default 30 km/h average speed
      final timeNeededSeconds = _distanceToDestination / speed;
      _estimatedArrivalTime = DateTime.now().add(Duration(seconds: timeNeededSeconds.toInt()));

      // Run arrival detection
      if (!dest.visited) {
        _arrivalService.checkArrival(
          currentPosition: position,
          destination: dest,
          onArrived: (double distance) {
            _voiceGuidanceService.speak("You have arrived at ${dest.name}");
            _hasArrivedAtDestination = true;
          },
        );
      }
    } else {
      _distanceToDestination = 0.0;
      _estimatedArrivalTime = null;
    }

    notifyListeners();
  }

  void _onLocationError(String error) {
    _locationTrackerError = error;
    notifyListeners();
  }

  void clearLocationTrackerError() {
    _locationTrackerError = null;
    notifyListeners();
  }

  void dismissArrivalNotification() {
    _hasArrivedAtDestination = false;
    notifyListeners();
  }

  Future<void> updateJourneySettings(JourneySettings settings) async {
    _journeySettings = settings;
    _arrivalService.updateRadius(settings.arrivalRadius);
    _voiceGuidanceService.updateSettings(enabled: settings.voiceGuidance);

    if (_journeyState.isJourneyActive) {
      _startLocationTracking();
    } else {
      if (settings.keepScreenAwake) {
        WakelockPlus.enable().catchError((_) {});
      } else {
        WakelockPlus.disable().catchError((_) {});
      }
    }

    await StorageService.saveJourneySettings(settings.toMap());
    notifyListeners();
  }

  @override
  void dispose() {
    _trackerSubscription?.cancel();
    _trackerErrorSubscription?.cancel();
    _locationTrackerService.dispose();
    _voiceGuidanceService.stop();
    super.dispose();
  }

  double _calculateRemainingDistance(int fromStopIndex) {
    if (fromStopIndex < 0 || fromStopIndex >= _stops.length) return 0.0;
    double dist = 0.0;
    var current = _stops[fromStopIndex];
    for (var i = fromStopIndex + 1; i < _stops.length; i++) {
      dist += _distanceBetween(
        current.latitude,
        current.longitude,
        _stops[i].latitude,
        _stops[i].longitude,
      );
      current = _stops[i];
    }
    dist += _distanceBetween(
      current.latitude,
      current.longitude,
      _home.latitude,
      _home.longitude,
    );
    return dist;
  }
}

class RouteSegmentInfo {
  final int segmentIndex;
  final int pointCount;
  final LatLng firstPoint;
  final LatLng? secondPoint;
  final LatLng lastPoint;
  final String sourceType;

  RouteSegmentInfo({
    required this.segmentIndex,
    required this.pointCount,
    required this.firstPoint,
    required this.secondPoint,
    required this.lastPoint,
    required this.sourceType,
  });
}