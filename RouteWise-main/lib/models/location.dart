class Location {
  final String id;
  final String name;
  final String? placeId;
  final double latitude;
  final double longitude;
  final bool visited;

  const Location({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.visited = false,
  });

  Location copyWith({
    String? id,
    String? name,
    String? placeId,
    double? latitude,
    double? longitude,
    bool? visited,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      placeId: placeId ?? this.placeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      visited: visited ?? this.visited,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'placeId': placeId,
      'latitude': latitude,
      'longitude': longitude,
      'visited': visited,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    double parseDouble(Object? value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return Location(
      id: map['id'] as String,
      name: map['name'] as String,
      placeId: map['placeId'] as String?,
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      visited: map['visited'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location &&
        other.id == id &&
        other.name == name &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.visited == visited;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        visited.hashCode;
  }
}
