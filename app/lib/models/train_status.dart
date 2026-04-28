class TrainStatus {
  final String trainNumber;
  final double currentLat;
  final double currentLon;
  final int delayMinutes;
  final DateTime lastFetchedAt;

  TrainStatus({
    required this.trainNumber,
    required this.currentLat,
    required this.currentLon,
    required this.delayMinutes,
    required this.lastFetchedAt,
  });

  factory TrainStatus.fromJson(Map<String, dynamic> json) {
    return TrainStatus(
      trainNumber: json['train_number'] as String,
      currentLat: (json['current_lat'] as num).toDouble(),
      currentLon: (json['current_lon'] as num).toDouble(),
      delayMinutes: json['delay_minutes'] as int,
      lastFetchedAt: DateTime.parse(json['last_fetched_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'train_number': trainNumber,
      'current_lat': currentLat,
      'current_lon': currentLon,
      'delay_minutes': delayMinutes,
      'last_fetched_at': lastFetchedAt.toIso8601String(),
    };
  }

  bool get isDelayed => delayMinutes > 0;

  String get delayText {
    if (delayMinutes <= 0) return 'On Time';
    if (delayMinutes < 60) return '$delayMinutes min late';
    final hours = delayMinutes ~/ 60;
    final mins = delayMinutes % 60;
    return '${hours}h ${mins}m late';
  }
}
