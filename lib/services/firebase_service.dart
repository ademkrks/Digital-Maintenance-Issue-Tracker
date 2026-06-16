import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/device.dart';
import '../models/maintenance_log.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Kimlik doğrulama durumu akışı
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mevcut kullanıcının e-posta adresini al
  String? get currentUserEmail => _auth.currentUser?.email;

  // Kullanıcı girişi
  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Kullanıcı çıkışı
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Kullanıcı detaylarını (rol) al
  Future<UserModel?> getUserModel(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(uid, doc.data()!);
      }
    } catch (e) {
      debugPrint('Error getting user details: $e');
    }
    return null;
  }

  // Envanter listesini akış olarak al
  Stream<List<Device>> streamInventory() {
    return _db.collection('inventory').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Device.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Kronolojik olarak sıralanmış bakım günlüklerini akış olarak al (en yeni ilk)
  Stream<List<MaintenanceLog>> streamMaintenanceLogs() {
    return _db
        .collection('maintenance_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MaintenanceLog.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Firebase Storage'a görseli byte olarak yükle ve URL'sini döndür (platformlar arası güvenli)
  Future<String> uploadImageBytes(
    Uint8List bytes,
    String deviceSerialNumber,
  ) async {
    final fileName =
        '${deviceSerialNumber}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('fault_photos/$fileName');
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  // Bakım günlüğünü ekle ve cihaz durumunu bir toplu işlemle (batch transaction) güncelle
  Future<void> addMaintenanceLog({
    required String deviceId,
    required String deviceName,
    required String deviceSerialNumber,
    required String status,
    required String notes,
    String? photoUrl,
  }) async {
    final batch = _db.batch();

    // 1. Envanterdeki cihaza referans
    final deviceRef = _db.collection('inventory').doc(deviceId);
    batch.update(deviceRef, {'status': status});

    // 2. Yeni günlük belgesine referans
    final logRef = _db.collection('maintenance_logs').doc();
    final log = MaintenanceLog(
      id: logRef.id,
      deviceId: deviceId,
      deviceName: deviceName,
      deviceSerialNumber: deviceSerialNumber,
      status: status,
      notes: notes,
      photoUrl: photoUrl,
      reportedBy: currentUserEmail ?? 'unknown_personnel',
      timestamp: DateTime.now(),
    );

    batch.set(logRef, log.toMap());
    await batch.commit();
  }

  // Boşsa başlangıç cihazlarını envantere ekle (seeding)
  Future<void> seedInitialInventory() async {
    final existing = await _db.collection('inventory').limit(1).get();
    if (existing.docs.isEmpty) {
      final initialDevices = [
        {
          'name': 'Operator HMI Touch 10"',
          'serialNumber': 'SN-HMI-10294',
          'type': 'HMI',
          'status': 'Working',
        },
        {
          'name': 'Status LED Matrix Board',
          'serialNumber': 'SN-LED-38472',
          'type': 'LED',
          'status': 'Working',
        },
        {
          'name': 'Control Panel Switchbox B',
          'serialNumber': 'SN-PNL-88273',
          'type': 'Panel',
          'status': 'Working',
        },
        {
          'name': 'LCD Telemetry Display',
          'serialNumber': 'SN-LCD-44910',
          'type': 'LCD',
          'status': 'Working',
        },
      ];

      for (var dev in initialDevices) {
        await _db.collection('inventory').add(dev);
      }
    }
  }

  // Yönetici Çözümü: İkinci bir Firebase Uygulaması kullanarak Firebase Auth ve Firestore'da yeni kullanıcı oluştur
  Future<void> createNewUser({
    required String email,
    required String password,
    required String role,
  }) async {
    // Yöneticinin varsayılan uygulamadaki oturumunun aktif kalması için geçici bir ikincil uygulama başlat.
    final appName =
        'TempRegistrationApp_${DateTime.now().millisecondsSinceEpoch}';

    FirebaseApp secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );
    } catch (e) {
      rethrow;
    }

    try {
      final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(
        app: secondaryApp,
      );

      // Kimlik bilgilerini kaydet
      final UserCredential creds = await secondaryAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final String newUid = creds.user!.uid;

      // Bilgileri Firestore'a ekle
      await _db.collection('users').doc(newUid).set({
        'email': email,
        'role': role,
      });

      // Geçici oturumdan çıkış yap
      await secondaryAuth.signOut();
    } finally {
      // İkincil uygulamayı temizle
      await secondaryApp.delete();
    }
  }
}
