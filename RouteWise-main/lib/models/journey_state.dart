import '../models/location.dart';

class JourneyState {
  final bool isJourneyActive;
  final int currentStopIndex;
  final Location? currentDestination;
  final List<Location> completedStops;
  final List<Location> remainingStops;
  final DateTime? journeyStartTime;
  final double totalDistance;
  final double estimatedRemainingDistance;

  const JourneyState({
    this.isJourneyActive = false,
    this.currentStopIndex = -1,
    this.currentDestination,
    this.completedStops = const [],
    this.remainingStops = const [],
    this.journeyStartTime,
    this.totalDistance = 0.0,
    this.estimatedRemainingDistance = 0.0,
  });

  JourneyState copyWith({
    bool? isJourneyActive,
    int? currentStopIndex,
    Location? currentDestination,
    List<Location>? completedStops,
    List<Location>? remainingStops,
    DateTime? journeyStartTime,
    double? totalDistance,
    double? estimatedRemainingDistance,
  }) {
    return JourneyState(
      isJourneyActive: isJourneyActive ?? this.isJourneyActive,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      currentDestination: currentDestination ?? this.currentDestination,
      completedStops: completedStops ?? this.completedStops,
      remainingStops: remainingStops ?? this.remainingStops,
      journeyStartTime: journeyStartTime ?? this.journeyStartTime,
      totalDistance: totalDistance ?? this.totalDistance,
      estimatedRemainingDistance: estimatedRemainingDistance ?? this.estimatedRemainingDistance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isJourneyActive': isJourneyActive,
      'currentStopIndex': currentStopIndex,
      'currentDestination': currentDestination?.toMap(),
      'completedStops': completedStops.map((stop) => stop.toMap()).toList(),
      'remainingStops': remainingStops.map((stop) => stop.toMap()).toList(),
      'journeyStartTime': journeyStartTime?.toIso8601String(),
      'totalDistance': totalDistance,
      'estimatedRemainingDistance': estimatedRemainingDistance,
    };
  }

  factory JourneyState.fromMap(Map<String, dynamic> map) {
    return JourneyState(
      isJourneyActive: map['isJourneyActive'] as bool? ?? false,
      currentStopIndex: (map['currentStopIndex'] as num?)?.toInt() ?? -1,
      currentDestination: map['currentDestination'] != null
          ? Location.fromMap(Map<String, dynamic>.from(map['currentDestination'] as Map))
          : null,
      completedStops: (map['completedStops'] as List<dynamic>? ?? const [])
          .map((stop) => Location.fromMap(Map<String, dynamic>.from(stop as Map)))
          .toList(),
      remainingStops: (map['remainingStops'] as List<dynamic>? ?? const [])
          .map((stop) => Location.fromMap(Map<String, dynamic>.from(stop as Map)))
          .toList(),
      journeyStartTime: map['journeyStartTime'] != null
          ? DateTime.tryParse(map['journeyStartTime'] as String)
          : null,
      totalDistance: (map['totalDistance'] as num?)?.toDouble() ?? 0.0,
      estimatedRemainingDistance: (map['estimatedRemainingDistance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
