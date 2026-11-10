import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/journey_state.dart';

class JourneyService {
  static const String _boxName = 'routewise_journey';
  static const String _journeyStateKey = 'active_journey_state';

  static Box<dynamic>? _box;

  static Future<void> initialize() async {
    if (_box != null) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  static Future<void> saveJourneyState(JourneyState state) async {
    try {
      await initialize();
      await _box?.put(_journeyStateKey, jsonEncode(state.toMap()));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JourneyService] saveJourneyState failed: $e');
      }
    }
  }

  static Future<JourneyState?> loadJourneyState() async {
    try {
      await initialize();
      final value = _box?.get(_journeyStateKey);
      if (value is! String || value.isEmpty) return null;
      return JourneyState.fromMap(jsonDecode(value) as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JourneyService] loadJourneyState failed: $e');
      }
      return null;
    }
  }

  static Future<void> clearJourneyState() async {
    try {
      await initialize();
      await _box?.delete(_journeyStateKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JourneyService] clearJourneyState failed: $e');
      }
    }
  }
}
