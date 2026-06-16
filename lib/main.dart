import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/personnel_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat (yapılandırma kimlik bilgileri henüz ayarlanmamışsa güvenli bir şekilde yakala)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint(
      'Firebase initialization failed: $e. Running in mock or pending configuration mode.',
    );
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // Yeni Hali
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Maintenance & Issue Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6366F1), // İndigo
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Arduvaz 900
        cardColor: const Color(0xFF1E293B), // Arduvaz 800
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF06B6D4), // Turkuaz
          error: Color(0xFFEF4444),
          surfaceContainer: Color(0xFF1E293B),
          surface: Color(0xFF0F172A),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: Color(0xFFF1F5F9)),
          bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  // Yeni Hali
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // 1. Yükleme Durumu
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
              SizedBox(height: 16),
              Text(
                'Syncing with Firebase...',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Kimlik Doğrulanmış Durum
    if (authProvider.isAuthenticated) {
      final user = authProvider.userModel;

      // Rol hala yükleniyorsa veya null ise
      if (user == null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loading operator details...',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => authProvider.logout(),
                  child: const Text('Cancel / Sign Out'),
                ),
              ],
            ),
          ),
        );
      }

      // Rolü kontrol et
      if (user.role == 'admin') {
        return const AdminScreen();
      } else if (user.role == 'personnel') {
        return const PersonnelScreen();
      } else {
        // Bilinmeyen rol için koruyucu durum
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.gpp_bad_outlined,
                    size: 64,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your email (${user.email}) does not have an assigned system role.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => authProvider.logout(),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // 3. Kimlik Doğrulanmamış Durum
    return const LoginScreen();
  }
}
