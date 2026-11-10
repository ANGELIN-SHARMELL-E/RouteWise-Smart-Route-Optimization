import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:routewise/models/location.dart';
import 'package:routewise/models/journey_state.dart';
import 'package:routewise/models/journey_settings.dart';
import 'package:routewise/services/route_provider.dart';
import 'package:routewise/services/journey_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    // Prevent real Hive from failing inside tests
    Hive.init('build/test/hive');
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'GOOGLE_MAPS_API_KEY=MOCK_KEY');
  });

  group('JourneyState Model Tests', () {
    test('default constructor creates empty state', () {
      const state = JourneyState();
      expect(state.isJourneyActive, isFalse);
      expect(state.currentStopIndex, -1);
      expect(state.currentDestination, isNull);
      expect(state.completedStops, isEmpty);
      expect(state.remainingStops, isEmpty);
      expect(state.totalDistance, 0.0);
    });

    test('copyWith updates fields correctly', () {
      const state = JourneyState();
      final updated = state.copyWith(
        isJourneyActive: true,
        currentStopIndex: 1,
        totalDistance: 5.5,
      );
      expect(updated.isJourneyActive, isTrue);
      expect(updated.currentStopIndex, 1);
      expect(updated.totalDistance, 5.5);
    });

    test('toMap and fromMap conversions are consistent', () {
      final stop = const Location(
        id: 'stop1',
        name: 'Test Stop',
        latitude: 10.0,
        longitude: 20.0,
      );
      final state = JourneyState(
        isJourneyActive: true,
        currentStopIndex: 0,
        currentDestination: stop,
        completedStops: [stop],
        remainingStops: [stop],
        totalDistance: 12.3,
        estimatedRemainingDistance: 45.6,
        journeyStartTime: DateTime.parse('2026-07-17T12:00:00Z'),
      );

      final map = state.toMap();
      final reconstructed = JourneyState.fromMap(map);

      expect(reconstructed.isJourneyActive, state.isJourneyActive);
      expect(reconstructed.currentStopIndex, state.currentStopIndex);
      expect(reconstructed.currentDestination?.id, state.currentDestination?.id);
      expect(reconstructed.completedStops.first.id, state.completedStops.first.id);
      expect(reconstructed.totalDistance, state.totalDistance);
      expect(reconstructed.estimatedRemainingDistance, state.estimatedRemainingDistance);
      expect(reconstructed.journeyStartTime, state.journeyStartTime);
    });
  });

  group('JourneySettings Model Tests', () {
    test('default constructor creates correct defaults', () {
      const settings = JourneySettings();
      expect(settings.arrivalRadius, 50.0);
      expect(settings.locationAccuracy, 'high');
      expect(settings.voiceGuidance, isTrue);
      expect(settings.autoCenterMap, isTrue);
      expect(settings.keepScreenAwake, isTrue);
    });

    test('copyWith works correctly', () {
      const settings = JourneySettings();
      final updated = settings.copyWith(
        arrivalRadius: 100.0,
        voiceGuidance: false,
      );
      expect(updated.arrivalRadius, 100.0);
      expect(updated.locationAccuracy, 'high');
      expect(updated.voiceGuidance, isFalse);
    });

    test('toMap and fromMap are consistent', () {
      const settings = JourneySettings(
        arrivalRadius: 75.0,
        locationAccuracy: 'medium',
        voiceGuidance: false,
        autoCenterMap: false,
        keepScreenAwake: false,
      );
      final map = settings.toMap();
      final reconstructed = JourneySettings.fromMap(map);
      expect(reconstructed.arrivalRadius, 75.0);
      expect(reconstructed.locationAccuracy, 'medium');
      expect(reconstructed.voiceGuidance, isFalse);
      expect(reconstructed.autoCenterMap, isFalse);
      expect(reconstructed.keepScreenAwake, isFalse);
    });
  });
}
