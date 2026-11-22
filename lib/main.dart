import 'package:material_ui/material_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/rak/rak_screen.dart';
import 'screens/rak/tambah_buku_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'screens/clubs/club_list_screen.dart';
import 'screens/clubs/club_form_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Muat file .env (berisi URL dan kunci Supabase)
  // 2. Hubungkan ke Supabase
  String? errorSetup;
  try {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
  } catch (_) {
    errorSetup =
        'Isi SUPABASE_URL dan SUPABASE_ANON_KEY di file .env '
        'dengan data dari dashboard Supabase, lalu jalankan ulang aplikasi.';
  }

  runApp(BacakalaApp(errorSetup: errorSetup));
}

class BacakalaApp extends StatelessWidget {
  final String? errorSetup;
  const BacakalaApp({super.key, this.errorSetup});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bacakala',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Jika .env belum diisi, tampilkan petunjuk (bukan crash)
      home: errorSetup != null
          ? _SetupErrorPage(pesan: errorSetup!)
          : const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(),
        '/profile': (_) => const ProfileScreen(showBottomNav: true),
        '/rak': (_) => const RakScreen(),
        '/rak/tambah': (_) => const TambahBukuScreen(),
        '/klub': (_) => const ClubListScreen(),
        '/klub/buat': (_) => const ClubFormScreen(),
        '/statistik': (context) => StatsScreen(
              onStartSession: () =>
                  Navigator.pushReplacementNamed(context, '/rak'),
            ),
      },
    );
  }
}

class _SetupErrorPage extends StatelessWidget {
  final String pesan;
  const _SetupErrorPage({required this.pesan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('bacakala', style: AppText.logo),
              const SizedBox(height: 16),
              Text(pesan, textAlign: TextAlign.center, style: AppText.subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
