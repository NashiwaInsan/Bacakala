import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Layar awal: cek sesi, lalu arahkan ke /home atau /login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _cekSesi();
  }

  Future<void> _cekSesi() async {
    // Jeda singkat agar logo sempat terlihat
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final adaSesi = _auth.currentSession != null;
    Navigator.of(context).pushReplacementNamed(adaSesi ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('bacakala', style: AppText.logoSplash)),
    );
  }
}
