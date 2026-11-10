import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'js_util.dart' as js;
import '../models/location.dart';

class DirectionsResponse {
  final bool success;
  final int distanceMeters;
  final int durationSeconds;
  final List<LatLng> points;
  final String apiStatus;
  final String? errorMessage;

  DirectionsResponse({
    required this.success,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.points,
    required this.apiStatus,
    this.errorMessage,
  });
}

class DirectionsService {
  static String get _apiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_API_KEY_HERE';
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  final Map<String, DirectionsResponse> _cache = {};

  Future<DirectionsResponse> requestDirections(
      Location origin, Location destination) async {
    final cacheKey =
        '${origin.latitude},${origin.longitude}->${destination.latitude},${destination.longitude}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    if (kIsWeb) {
      try {
        final jsPromise = js.callMethod<dynamic>(js.globalThis, 'routewise_getDirections', [
          origin.latitude,
          origin.longitude,
          destination.latitude,
          destination.longitude,
        ]);
        final jsonString = await js.promiseToFuture<String>(jsPromise);
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        
        DirectionsResponse result;
        if (map['success'] as bool? ?? false) {
          final pointsList = (map['points'] as List<dynamic>)
              .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
              .toList();
          result = DirectionsResponse(
            success: true,
            distanceMeters: (map['distanceMeters'] as num).toInt(),
            durationSeconds: (map['durationSeconds'] as num).toInt(),
            points: pointsList,
            apiStatus: 'OK',
          );
        } else {
          result = DirectionsResponse(
            success: false,
            distanceMeters: 0,
            durationSeconds: 0,
            points: [],
            apiStatus: map['status'] as String? ?? 'ERROR',
          );
        }
        
        _cache[cacheKey] = result;
        return result;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[DirectionsService] Web directions error: $e');
        }
        return DirectionsResponse(
          success: false,
          distanceMeters: 0,
          durationSeconds: 0,
          points: [],
          apiStatus: 'ERROR',
          errorMessage: e.toString(),
        );
      }
    }

    final result = await _restRequest(origin, destination);
    _cache[cacheKey] = result;
    return result;
  }

  // ── Mobile: REST Directions API ────────────────────────────────────────────

  Future<DirectionsResponse> _restRequest(
      Location origin, Location destination) async {
    final uri = Uri.parse('$_baseUrl'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$_apiKey&mode=driving');

    try {
      final response = await http.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final String apiStatus = body['status'] as String? ?? 'UNKNOWN';
      final routesReturned = (body['routes'] as List).length;

      if (response.statusCode != 200 ||
          apiStatus != 'OK' ||
          routesReturned == 0) {
        return DirectionsResponse(
          success: false,
          distanceMeters: 0,
          durationSeconds: 0,
          points: [],
          apiStatus: apiStatus,
          errorMessage: apiStatus == 'ZERO_RESULTS'
              ? 'No driving route was found for this trip.'
              : body['error_message'] as String? ?? apiStatus,
        );
      }

      final route = (body['routes'] as List).first as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>;
      int totalDistance = 0;
      int totalDuration = 0;
      final points = <LatLng>[];

      for (final leg in legs) {
        totalDistance +=
            (leg['distance'] as Map<String, dynamic>)['value'] as int;
        totalDuration +=
            (leg['duration'] as Map<String, dynamic>)['value'] as int;
        for (final step in leg['steps'] as List<dynamic>) {
          final encoded =
              (step['polyline'] as Map<String, dynamic>)['points'] as String;
          points.addAll(_decodePolyline(encoded));
        }
      }

      if (points.length <= 2 && route.containsKey('overview_polyline')) {
        final overview =
            (route['overview_polyline'] as Map<String, dynamic>)['points']
                as String;
        final overviewPts = _decodePolyline(overview);
        if (overviewPts.length > points.length) {
          points
            ..clear()
            ..addAll(overviewPts);
        }
      }

      return DirectionsResponse(
        success: true,
        distanceMeters: totalDistance,
        durationSeconds: totalDuration,
        points: points,
        apiStatus: apiStatus,
      );
    } catch (e) {
      return DirectionsResponse(
        success: false,
        distanceMeters: 0,
        durationSeconds: 0,
        points: [],
        apiStatus: 'ERROR',
        errorMessage: e.toString(),
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0, byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
