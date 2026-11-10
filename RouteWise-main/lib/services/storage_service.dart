import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/location.dart';
import '../models/route_snapshot.dart';

class StorageService {
  static const String _boxName = 'routewise_storage';
  static const String _homeKey = 'home';
  static const String _stopsKey = 'stops';
  static const String _routeKey = 'route_snapshot';

  static Box<dynamic>? _box;

  static Future<void> initialize() async {
    if (_box != null) {
      return;
    }

    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  static Box<dynamic> get _storageBox {
    final box = _box;
    if (box == null) {
      throw StateError('StorageService.initialize() must be called first.');
    }
    return box;
  }

  static Future<void> saveHome(Location home) async {
    await _storageBox.put(_homeKey, jsonEncode(home.toMap()));
  }

  static Future<Location?> loadHome() async {
    final value = _storageBox.get(_homeKey);
    if (value is! String || value.isEmpty) {
      return null;
    }

    try {
      return Location.fromMap(jsonDecode(value) as Map<String, dynamic>);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[StorageService] loadHome failed: $error');
      }
      return null;
    }
  }

  static Future<void> saveStops(List<Location> stops) async {
    await _storageBox.put(
      _stopsKey,
      jsonEncode(stops.map((stop) => stop.toMap()).toList()),
    );
  }

  static Future<List<Location>> loadStops() async {
    final value = _storageBox.get(_stopsKey);
    if (value is! String || value.isEmpty) {
      return [];
    }

    try {
      final data = jsonDecode(value) as List<dynamic>;
      return data
          .map((entry) => Location.fromMap(Map<String, dynamic>.from(entry as Map)))
          .toList();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[StorageService] loadStops failed: $error');
      }
      return [];
    }
  }

  static Future<void> saveRouteSnapshot(RouteSnapshot snapshot) async {
    await _storageBox.put(_routeKey, jsonEncode(snapshot.toMap()));
  }

  static Future<RouteSnapshot?> loadRouteSnapshot() async {
    final value = _storageBox.get(_routeKey);
    if (value is! String || value.isEmpty) {
      return null;
    }

    try {
      return RouteSnapshot.fromMap(jsonDecode(value) as Map<String, dynamic>);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[StorageService] loadRouteSnapshot failed: $error');
      }
      return null;
    }
  }

  static Future<void> clearRoute() async {
    await Future.wait([
      _storageBox.delete(_stopsKey),
      _storageBox.delete(_routeKey),
    ]);
  }

  static const String _settingsKey = 'journey_settings';

  static Future<void> saveJourneySettings(Map<String, dynamic> settingsMap) async {
    await _storageBox.put(_settingsKey, jsonEncode(settingsMap));
  }

  static Future<Map<String, dynamic>?> loadJourneySettings() async {
    final value = _storageBox.get(_settingsKey);
    if (value is! String || value.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}