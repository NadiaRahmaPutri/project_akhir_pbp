import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Config.supabaseUrl.isEmpty || Config.supabaseKey.isEmpty) {
    runApp(const _KonfigurasiKosong());
    return;
  }

  await Supabase.initialize(
    url: Config.supabaseUrl,
    // Jika muncul error "no named parameter publishableKey",
    // ganti baris ini menjadi: anonKey: Config.supabaseKey,
    publishableKey: Config.supabaseKey,
  );

  runApp(const KuisApp());
}

class KuisApp extends StatelessWidget {
  const KuisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Pembelajaran & Kuis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F6F8B)),
      ),
      home: const AuthGate(),
    );
  }
}

/// Menentukan halaman awal: login jika belum masuk, beranda jika sudah.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;
        return session == null ? const LoginScreen() : const HomeScreen();
      },
    );
  }
}

class _KonfigurasiKosong extends StatelessWidget {
  const _KonfigurasiKosong();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'SUPABASE_URL dan SUPABASE_KEY belum diisi.\n'
              'Jalankan aplikasi dengan --dart-define atau atur '
              'di .vscode/launch.json.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
