import 'package:material_ui/material_ui.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bookshelf_illustration.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _masuk() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    // Validasi sederhana
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _pesan('Format email tidak valid');
      return;
    }
    if (pass.length < 8) {
      _pesan('Kata sandi minimal 8 karakter');
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.signIn(email, pass);
      if (!mounted) return;
      // Ke Beranda dan hapus riwayat navigasi
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } on ServiceException catch (e) {
      _pesan(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool rahasia = false,
    TextInputType? tipe,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: rahasia,
          keyboardType: tipe,
          style: AppText.input,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Isi bisa di-scroll; teks "Daftar" menempel di bawah layar
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.authPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    Text('bacakala', style: AppText.logo),
                    const SizedBox(height: 35),
                    const BookshelfIllustration(),
                    const SizedBox(height: 35),
                    Text(
                      'Masuk dulu,\nlanjut halaman\nberikutnya.',
                      style: AppText.display,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rak, sesi, dan catatanmu tersimpan di akun ini.',
                      style: AppText.subtitle,
                    ),
                    const SizedBox(height: 30),
                    _field(
                      'Email',
                      _emailCtrl,
                      tipe: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _field('Kata sandi', _passCtrl, rahasia: true),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _pesan('Segera hadir'),
                        child: Text('Lupa kata sandi?', style: AppText.link),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: AppSizes.buttonHeight,
                      child: FilledButton(
                        onPressed: _loading ? null : _masuk,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text('Masuk'),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pushNamed('/register'),
                          child: Text.rich(
                            TextSpan(
                              text: 'Belum punya akun? ',
                              style: AppText.body,
                              children: [
                                TextSpan(
                                  text: 'Daftar',
                                  style: AppText.link.copyWith(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
