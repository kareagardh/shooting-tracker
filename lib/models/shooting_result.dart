import 'package:uuid/uuid.dart';

class ShootingResult {
  final String id;
  final DateTime dateTime;
  final double score;
  final double? latitude;
  final double? longitude;
  final String venueName;
  final String? photoPath;

  ShootingResult({
    String? id,
    required this.dateTime,
    required this.score,
    this.latitude,
    this.longitude,
    required this.venueName,
    this.photoPath,
  }) : id = id ?? const Uuid().v4();

  factory ShootingResult.fromJson(Map<String, dynamic> json) {
    return ShootingResult(
      id: json['id'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      score: (json['score'] as num).toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      venueName: json['venueName'] as String,
      photoPath: json['photoPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'score': score,
        'latitude': latitude,
        'longitude': longitude,
        'venueName': venueName,
        'photoPath': photoPath,
      };
}
