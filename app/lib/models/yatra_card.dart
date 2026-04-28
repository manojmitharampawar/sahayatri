class YatraCard {
  final int id;
  final int userId;
  final String pnr;
  final String trainNumber;
  final int boardingStationId;
  final int destinationStationId;
  final String berthInfo;
  final DateTime journeyDate;
  final String status;
  final DateTime createdAt;

  YatraCard({
    required this.id,
    required this.userId,
    required this.pnr,
    required this.trainNumber,
    required this.boardingStationId,
    required this.destinationStationId,
    required this.berthInfo,
    required this.journeyDate,
    required this.status,
    required this.createdAt,
  });

  factory YatraCard.fromJson(Map<String, dynamic> json) {
    return YatraCard(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      pnr: json['pnr'] as String,
      trainNumber: json['train_number'] as String,
      boardingStationId: json['boarding_station_id'] as int,
      destinationStationId: json['destination_station_id'] as int,
      berthInfo: (json['berth_info'] as String?) ?? '',
      journeyDate: DateTime.parse(json['journey_date'] as String),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'pnr': pnr,
      'train_number': trainNumber,
      'boarding_station_id': boardingStationId,
      'destination_station_id': destinationStationId,
      'berth_info': berthInfo,
      'journey_date': journeyDate.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
