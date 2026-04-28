class Station {
  final int id;
  final String code;
  final String name;
  final double lat;
  final double lon;
  final String zone;

  Station({
    required this.id,
    required this.code,
    required this.name,
    required this.lat,
    required this.lon,
    required this.zone,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      zone: (json['zone'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'lat': lat,
      'lon': lon,
      'zone': zone,
    };
  }

  @override
  String toString() => '$name ($code)';
}
