import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/location.dart';
import 'js_util.dart' as js;

class GeocodingService {
  static String get _apiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_API_KEY_HERE';
  static const String _reverseGeocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

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
          id: placeId ?? 'geocoded_${latitude}_$longitude',
          placeId: placeId,
          name: map['name'] as String,
          latitude: latitude,
          longitude: longitude,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[GeocodingService] Web reverseGeocode error: $e');
        }
        return null;
      }
    }

    final uri = Uri.parse(
      '$_reverseGeocodeUrl?latlng=$latitude,$longitude&language=en&key=$_apiKey',
    );

    final response = await http.get(uri);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK') {
      debugPrint('[GeocodingService] reverse geocode failed: $status');
      return null;
    }

    final results = body['results'] as List<dynamic>;
    if (results.isEmpty) return null;

    final firstResult = results.first as Map<String, dynamic>;
    final formattedAddress = firstResult['formatted_address'] as String? ?? 'Current Location';

    return Location(
      id: 'current_location_${DateTime.now().millisecondsSinceEpoch}',
      name: formattedAddress,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
