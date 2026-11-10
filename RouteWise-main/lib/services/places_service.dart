import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/location.dart';
import '../models/place_suggestion.dart';
import 'js_util.dart' as js;

class PlacesService {
  static String get _apiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_API_KEY_HERE';
  static const String _autocompleteUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json';

  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    if (input.trim().isEmpty) {
      return [];
    }

    if (kIsWeb) {
      try {
        final jsPromise = js.callMethod<dynamic>(js.globalThis, 'routewise_autocomplete', [input]);
        final jsonString = await js.promiseToFuture<String>(jsPromise);
        final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          return PlaceSuggestion(
            placeId: map['placeId'] as String,
            description: map['description'] as String,
          );
        }).toList();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[PlacesService] Web autocomplete error: $e');
        }
        return [];
      }
    }

    try {
      final uri = Uri.parse(
        '$_autocompleteUrl?input=${Uri.encodeQueryComponent(input)}&types=geocode&language=en&key=$_apiKey',
      );
      final response = await http.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? 'UNKNOWN';
      if (status != 'OK') {
        if (kDebugMode) {
          debugPrint('[PlacesService] autocomplete failed: $status');
        }
        return [];
      }

      final predictions = body['predictions'] as List<dynamic>;
      return predictions
          .map((prediction) => PlaceSuggestion(
                placeId: prediction['place_id'] as String,
                description: prediction['description'] as String,
              ))
          .toList();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[PlacesService] autocomplete error: $error');
      }
      return [];
    }
  }

  // Backwards-compatible alias used by older call sites.
  Future<List<PlaceSuggestion>> fetchSuggestions(String input) async {
    return autocomplete(input);
  }

  Future<Location?> getPlaceDetails(String placeId) async {
    if (kIsWeb) {
      try {
        final jsPromise = js.callMethod<dynamic>(js.globalThis, 'routewise_placeDetails', [placeId]);
        final jsonString = await js.promiseToFuture<String>(jsPromise);
        final data = jsonDecode(jsonString);
        if (data == null) return null;
        final map = data as Map<String, dynamic>;
        return Location(
          id: placeId,
          placeId: placeId,
          name: map['name'] as String,
          latitude: (map['lat'] as num).toDouble(),
          longitude: (map['lng'] as num).toDouble(),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[PlacesService] Web placeDetails error: $e');
        }
        return null;
      }
    }

    try {
      final uri = Uri.parse(
        '$_detailsUrl?place_id=${Uri.encodeQueryComponent(placeId)}&fields=name,formatted_address,geometry&key=$_apiKey',
      );
      final response = await http.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? 'UNKNOWN';
      if (status != 'OK') {
        if (kDebugMode) {
          debugPrint('[PlacesService] place details failed: $status');
        }
        return null;
      }

      final result = body['result'] as Map<String, dynamic>;
      final geometry = result['geometry'] as Map<String, dynamic>;
      final location = geometry['location'] as Map<String, dynamic>;
      final name = result['formatted_address'] as String? ?? result['name'] as String? ?? 'Unknown place';

      return Location(
        id: placeId,
        placeId: placeId,
        name: name,
        latitude: (location['lat'] as num).toDouble(),
        longitude: (location['lng'] as num).toDouble(),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[PlacesService] place details error: $error');
      }
      return null;
    }
  }
}