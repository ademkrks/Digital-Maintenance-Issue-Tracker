import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceLog {
  final String id;
  final String deviceId;
  final String deviceName;
  final String deviceSerialNumber;
  final String status; // 'Working' (Çalışıyor), 'Faulty' (Arızalı), 'Missing' (Eksik/Kayıp)
  final String notes;
  final String? photoUrl;
  final String reportedBy; // Raporu kaydeden kullanıcının e-postası
  final DateTime timestamp;

  MaintenanceLog({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.deviceSerialNumber,
    required this.status,
    required this.notes,
    this.photoUrl,
    required this.reportedBy,
    required this.timestamp,
  });

  factory MaintenanceLog.fromMap(String id, Map<String, dynamic> map) {
    DateTime ts;
    if (map['timestamp'] is Timestamp) {
      ts = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      ts = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return MaintenanceLog(
      id: id,
      deviceId: map['deviceId'] ?? '',
      deviceName: map['deviceName'] ?? '',
      deviceSerialNumber: map['deviceSerialNumber'] ?? '',
      status: map['status'] ?? 'Working',
      notes: map['notes'] ?? '',
      photoUrl: map['photoUrl'],
      reportedBy: map['reportedBy'] ?? '',
      timestamp: ts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceSerialNumber': deviceSerialNumber,
      'status': status,
      'notes': notes,
      'photoUrl': photoUrl,
      'reportedBy': reportedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
