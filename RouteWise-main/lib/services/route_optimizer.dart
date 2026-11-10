import 'dart:math' as math;
import '../models/location.dart';

class RouteOptimizer {
  /// Calculates the distance in kilometers between two coordinates using the Haversine formula.
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double lat1Rad = _degreesToRadians(lat1);
    final double lat2Rad = _degreesToRadians(lat2);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1Rad) * math.cos(lat2Rad);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Calculates the total distance of a route starting at home, passing through all destinations
  /// in the given list, and returning to home.
  static double calculateRouteDistance(Location home, List<Location> route) {
    if (route.isEmpty) return 0.0;
    
    double totalDistance = 0.0;
    Location current = home;

    for (final stop in route) {
      totalDistance += calculateDistance(
        current.latitude,
        current.longitude,
        stop.latitude,
        stop.longitude,
      );
      current = stop;
    }

    totalDistance += calculateDistance(
      current.latitude,
      current.longitude,
      home.latitude,
      home.longitude,
    );

    return totalDistance;
  }

  /// Optimizes a list of destinations starting from home and returning to home.
  /// Uses an exact brute-force algorithm for 8 or fewer destinations to find the global optimum,
  /// and falls back to a Nearest Neighbor heuristic for larger sets to ensure speed.
  static List<Location> optimize(Location home, List<Location> destinations) {
    if (destinations.isEmpty) return [];
    
    if (destinations.length <= 8) {
      return _optimizeBruteForce(home, destinations);
    }
    
    return _optimizeNearestNeighbor(home, destinations);
  }

  /// Nearest Neighbor heuristic: O(N^2)
  static List<Location> _optimizeNearestNeighbor(Location home, List<Location> destinations) {
    final List<Location> unvisited = List.from(destinations);
    final List<Location> optimizedRoute = [];
    Location current = home;

    while (unvisited.isNotEmpty) {
      Location nearest = unvisited.first;
      double minDistance = double.infinity;
      int nearestIndex = 0;

      for (int i = 0; i < unvisited.length; i++) {
        final distance = calculateDistance(
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

  /// Exact Brute Force: generates permutations of destinations to find the absolute minimum distance.
  static List<Location> _optimizeBruteForce(Location home, List<Location> destinations) {
    double bestDistance = double.infinity;
    List<Location> bestRoute = [];

    void permute(List<Location> currentRoute, List<Location> remaining) {
      if (remaining.isEmpty) {
        final currentDistance = calculateRouteDistance(home, currentRoute);
        if (currentDistance < bestDistance) {
          bestDistance = currentDistance;
          bestRoute = List.from(currentRoute);
        }
        return;
      }

      for (int i = 0; i < remaining.length; i++) {
        final next = remaining[i];
        final newRoute = List<Location>.from(currentRoute)..add(next);
        final newRemaining = List<Location>.from(remaining)..removeAt(i);
        
        final partialDistance = calculateRouteDistance(home, newRoute);
        if (partialDistance < bestDistance) {
          permute(newRoute, newRemaining);
        }
      }
    }

    permute([], destinations);
    return bestRoute;
  }
}
