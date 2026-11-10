class JourneySettings {
  final double arrivalRadius;
  final String locationAccuracy; // 'low', 'medium', 'high'
  final bool voiceGuidance;
  final bool autoCenterMap;
  final bool keepScreenAwake;

  const JourneySettings({
    this.arrivalRadius = 50.0,
    this.locationAccuracy = 'high',
    this.voiceGuidance = true,
    this.autoCenterMap = true,
    this.keepScreenAwake = true,
  });

  JourneySettings copyWith({
    double? arrivalRadius,
    String? locationAccuracy,
    bool? voiceGuidance,
    bool? autoCenterMap,
    bool? keepScreenAwake,
  }) {
    return JourneySettings(
      arrivalRadius: arrivalRadius ?? this.arrivalRadius,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
      voiceGuidance: voiceGuidance ?? this.voiceGuidance,
      autoCenterMap: autoCenterMap ?? this.autoCenterMap,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'arrivalRadius': arrivalRadius,
      'locationAccuracy': locationAccuracy,
      'voiceGuidance': voiceGuidance,
      'autoCenterMap': autoCenterMap,
      'keepScreenAwake': keepScreenAwake,
    };
  }

  factory JourneySettings.fromMap(Map<String, dynamic> map) {
    return JourneySettings(
      arrivalRadius: (map['arrivalRadius'] as num?)?.toDouble() ?? 50.0,
      locationAccuracy: map['locationAccuracy'] as String? ?? 'high',
      voiceGuidance: map['voiceGuidance'] as bool? ?? true,
      autoCenterMap: map['autoCenterMap'] as bool? ?? true,
      keepScreenAwake: map['keepScreenAwake'] as bool? ?? true,
    );
  }
}
