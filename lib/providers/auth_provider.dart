import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _userModel != null;

  FirebaseService get service => _firebaseService;

  AuthProvider() {
    _init();
  }

  // Başlangıçta kimlik doğrulama durumunu kontrol et
  void _init() {
    _firebaseService.authStateChanges.listen((User? user) async {
      if (user == null) {
        _userModel = null;
        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = true;
        notifyListeners();
        _userModel = await _firebaseService.getUserModel(user.uid);
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  // Hataları temizle
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Kullanıcı girişi yap
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final creds = await _firebaseService.login(email.trim(), password);
      final model = await _firebaseService.getUserModel(creds.user!.uid);

      // 🚨 KRİTİK KONTROL NOKTASI
      // Eğer Firebase Auth girişi başarılı olduysa ama Firestore'da bu kullanıcıya rol verilmemişse:
      if (model == null) {
        _error =
            "Kimlik doğrulandı ancak veritabanında kullanıcı rolü bulunamadı. Lütfen yöneticinizle görüşün.";
        _userModel = null;
        _isLoading = false;

        // Cihazda yarım yamalak (rolsüz) bir oturum kalmaması için Auth oturumunu temizliyoruz:
        await _firebaseService.logout();

        notifyListeners();
        return false; // Login ekranına 'başarısız' döndür ki SnackBar tetiklensin!
      }

      // Her şey yolundaysa (model null değilse) normal akış devam eder
      _userModel = model;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'An error occurred during authentication.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Yeni kullanıcı kaydet (yönetici iş akışı)
  Future<bool> registerNewUser({
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.createNewUser(
        email: email.trim(),
        password: password,
        role: role,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Failed to register new user.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Kullanıcı çıkışı yap
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _firebaseService.logout();
    _userModel = null;
    _isLoading = false;
    notifyListeners();
  }
}
