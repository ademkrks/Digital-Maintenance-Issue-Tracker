class Device {
  final String id;
  final String name;
  final String serialNumber;
  final String type; // 'HMI', 'LED', 'Panel', 'LCD' cihaz tipleri
  final String status; // 'Working' (Çalışıyor), 'Faulty' (Arızalı), 'Missing' (Eksik/Kayıp) durumları

  Device({
    required this.id,
    required this.name,
    required this.serialNumber,
    required this.type,
    required this.status,
  });

  factory Device.fromMap(String id, Map<String, dynamic> map) {
    return Device(
      id: id,
      name: map['name'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      type: map['type'] ?? 'HMI',
      status: map['status'] ?? 'Working',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'serialNumber': serialNumber,
      'type': type,
      'status': status,
    };
  }

  Device copyWith({
    String? name,
    String? serialNumber,
    String? type,
    String? status,
  }) {
    return Device(
      id: id,
      name: name ?? this.name,
      serialNumber: serialNumber ?? this.serialNumber,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }
}
