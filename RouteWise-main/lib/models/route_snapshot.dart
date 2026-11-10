import 'location.dart';

class RouteSnapshot {
  final Location home;
  final List<Location> stops;
  final bool isOptimized;
  final String? routeApiStatus;
  final int routePointCount;
  final int routeDistanceMeters;
  final int goingDistanceMeters;
  final int returnDistanceMeters;
  final int routeDurationSeconds;

  const RouteSnapshot({
    required this.home,
    required this.stops,
    this.isOptimized = false,
    this.routeApiStatus,
    this.routePointCount = 0,
    this.routeDistanceMeters = 0,
    this.goingDistanceMeters = 0,
    this.returnDistanceMeters = 0,
    this.routeDurationSeconds = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'home': home.toMap(),
      'stops': stops.map((stop) => stop.toMap()).toList(),
      'isOptimized': isOptimized,
      'routeApiStatus': routeApiStatus,
      'routePointCount': routePointCount,
      'routeDistanceMeters': routeDistanceMeters,
      'goingDistanceMeters': goingDistanceMeters,
      'returnDistanceMeters': returnDistanceMeters,
      'routeDurationSeconds': routeDurationSeconds,
    };
  }

  factory RouteSnapshot.fromMap(Map<String, dynamic> map) {
    final homeMap = Map<String, dynamic>.from(map['home'] as Map);
    final stopMaps = (map['stops'] as List<dynamic>? ?? const [])
        .map((stop) => Location.fromMap(Map<String, dynamic>.from(stop as Map)))
        .toList();

    return RouteSnapshot(
      home: Location.fromMap(homeMap),
      stops: stopMaps,
      isOptimized: map['isOptimized'] as bool? ?? false,
      routeApiStatus: map['routeApiStatus'] as String?,
      routePointCount: (map['routePointCount'] as num?)?.toInt() ?? 0,
      routeDistanceMeters: (map['routeDistanceMeters'] as num?)?.toInt() ?? 0,
      goingDistanceMeters: (map['goingDistanceMeters'] as num?)?.toInt() ?? 0,
      returnDistanceMeters: (map['returnDistanceMeters'] as num?)?.toInt() ?? 0,
      routeDurationSeconds: (map['routeDurationSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}