import 'package:flutter_test/flutter_test.dart';
import 'package:digital_maintenance_tracker/models/user_model.dart';
import 'package:digital_maintenance_tracker/models/device.dart';
import 'package:digital_maintenance_tracker/models/maintenance_log.dart';

void main() {
  group('UserModel Tests', () {
    test('fromMap should parse role and details correctly', () {
      final map = {
        'email': 'operator1@tracker.com',
        'role': 'personnel',
      };
      
      final user = UserModel.fromMap('uid_123', map);
      
      expect(user.uid, 'uid_123');
      expect(user.email, 'operator1@tracker.com');
      expect(user.role, 'personnel');
      expect(user.isAdmin, false);
    });

    test('isAdmin getter should evaluate true for admin role', () {
      final map = {
        'email': 'admin@tracker.com',
        'role': 'admin',
      };
      
      final user = UserModel.fromMap('uid_admin', map);
      
      expect(user.isAdmin, true);
    });

    test('toMap should output expected structure', () {
      final user = UserModel(uid: 'uid_test', email: 'test@tracker.com', role: 'admin');
      final map = user.toMap();
      
      expect(map['email'], 'test@tracker.com');
      expect(map['role'], 'admin');
    });
  });

  group('Device Model Tests', () {
    test('fromMap and toMap mapping', () {
      final map = {
        'name': 'HMI Screen A',
        'serialNumber': 'SN-12345',
        'type': 'HMI',
        'status': 'Working',
      };

      final device = Device.fromMap('id_99', map);
      
      expect(device.id, 'id_99');
      expect(device.name, 'HMI Screen A');
      expect(device.serialNumber, 'SN-12345');
      expect(device.type, 'HMI');
      expect(device.status, 'Working');

      final outputMap = device.toMap();
      expect(outputMap['name'], 'HMI Screen A');
      expect(outputMap['status'], 'Working');
    });

    test('copyWith updates fields successfully', () {
      final device = Device(
        id: '1',
        name: 'LED Panel',
        serialNumber: 'SN-001',
        type: 'LED',
        status: 'Working',
      );

      final updated = device.copyWith(status: 'Faulty');
      
      expect(updated.id, '1');
      expect(updated.status, 'Faulty');
      expect(updated.name, 'LED Panel'); // stays same
    });
  });

  group('MaintenanceLog Model Tests', () {
    test('fromMap handles ISO String and formats map output', () {
      final nowStr = DateTime.now().toIso8601String();
      final map = {
        'deviceId': 'd_12',
        'deviceName': 'LCD Matrix',
        'deviceSerialNumber': 'SN-LCD',
        'status': 'Faulty',
        'notes': 'Pixel degradation observed',
        'photoUrl': 'https://storage/photo.jpg',
        'reportedBy': 'staff@tracker.com',
        'timestamp': nowStr,
      };

      final log = MaintenanceLog.fromMap('log_55', map);

      expect(log.id, 'log_55');
      expect(log.deviceId, 'd_12');
      expect(log.status, 'Faulty');
      expect(log.photoUrl, 'https://storage/photo.jpg');
      expect(log.reportedBy, 'staff@tracker.com');
      expect(log.timestamp.year, DateTime.now().year);
    });
  });
}
