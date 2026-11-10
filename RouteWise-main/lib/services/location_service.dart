import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/location.dart';
import 'js_util.dart' as js;

class LocationService {
  static String get _apiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_API_KEY_HERE';
  static const String _geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  Future<bool> requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          debugPrint('[LocationService] Permission check returned false, trying IP Geolocation fallback...');
        }
        final ipPos = await _getIPGeolocation();
        if (ipPos != null) return ipPos;
        return null;
      }

      // On web, high accuracy often times out on desktop browsers lacking GPS hardware.
      // We default to medium accuracy for web and high accuracy for mobile/desktop native.
      final accuracy = kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high;

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: accuracy,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[LocationService] First attempt failed ($e), retrying with lowest accuracy...');
        }
        try {
          // Fallback to lowest accuracy, which is much faster and less likely to time out as it uses IP/Cell tower location
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.lowest,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (e2) {
          if (kDebugMode) {
            debugPrint('[LocationService] Second attempt failed ($e2), falling back to IP Geolocation...');
          }
          final ipPos = await _getIPGeolocation();
          if (ipPos != null) return ipPos;
          rethrow;
        }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[LocationService] getCurrentPosition failed: $error');
      }
      return null;
    }
  }

  Future<Position?> _getIPGeolocation() async {
    // Try ipapi.co first
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final double? lat = (data['latitude'] as num?)?.toDouble();
        final double? lon = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          if (kDebugMode) {
            debugPrint('[LocationService] Resolved IP Geolocation via ipapi.co: $lat, $lon');
          }
          return Position(
            latitude: lat,
            longitude: lon,
            timestamp: DateTime.now(),
            accuracy: 5000,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocationService] ipapi.co fallback failed: $e');
      }
    }

    // Try freeipapi.com next
    try {
      final response = await http.get(Uri.parse('https://freeipapi.com/api/json')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final double? lat = (data['latitude'] as num?)?.toDouble();
        final double? lon = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          if (kDebugMode) {
            debugPrint('[LocationService] Resolved IP Geolocation via freeipapi.com: $lat, $lon');
          }
          return Position(
            latitude: lat,
            longitude: lon,
            timestamp: DateTime.now(),
            accuracy: 5000,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LocationService] freeipapi.com fallback failed: $e');
      }
    }

    return null;
  }

  Future<Location?> reverseGeocode(double latitude, double longitude) async {
    if (kIsWeb) {
      try {
        final jsPromise = js.callMethod<dynamic>(js.globalThis, 'routewise_reverseGeocode', [latitude, longitude]);
        final jsonString = await js.promiseToFuture<String>(jsPromise);
        final data = jsonDecode(jsonString);
        if (data == null) return null;
        final map = data as Map<String, dynamic>;
        final placeId = map['placeId'] as String?;
        return Location(
          id: placeId ?? 'home_${DateTime.now().millisecondsSinceEpoch}',
          placeId: placeId,
          name: map['name'] as String,
          latitude: latitude,
          longitude: longitude,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[LocationService] Web reverseGeocode failed: $e');
        }
        return null;
      }
    }

    try {
      final uri = Uri.parse('$_geocodeUrl?latlng=$latitude,$longitude&language=en&key=$_apiKey');
      final response = await http.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? 'UNKNOWN';
      if (status != 'OK') {
        if (kDebugMode) {
          debugPrint('[LocationService] reverseGeocode failed: $status');
        }
        return null;
      }

      final results = body['results'] as List<dynamic>;
      if (results.isEmpty) {
        return null;
      }

      final firstResult = results.first as Map<String, dynamic>;
      final formattedAddress = firstResult['formatted_address'] as String? ?? 'Current Location';

      return Location(
        id: 'home_${DateTime.now().millisecondsSinceEpoch}',
        name: formattedAddress,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[LocationService] reverseGeocode failed: $error');
      }
      return null;
    }
  }
}