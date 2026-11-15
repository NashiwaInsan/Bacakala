import 'package:material_ui/material_ui.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = AuthService();
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  // Indikator "Minimal 8 karakter" berubah langsung saat mengetik
  bool get _passCukup => _passCtrl.text.length >= 8;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _daftar() async {
    final nama = _namaCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (nama.isEmpty) {
      _pesan('Nama wajib diisi');
      return;
    }
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
      final langsungMasuk = await _auth.signUp(nama, email, pass);
      if (!mounted) return;
      if (langsungMasuk) {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      } else {
        // Supabase mewajibkan konfirmasi email -> belum ada sesi
        _pesan('Cek email untuk konfirmasi akun');
        Navigator.of(context).pop();
      }
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
    ValueChanged<String>? onChanged,
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
          onChanged: onChanged,
          style: AppText.input,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final warnaSyarat = _passCukup ? AppColors.primary : AppColors.textHint;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.authPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Tombol kembali ke Login
                    Transform.translate(
                      offset: const Offset(-24, 0),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.chevron_left,
                          size: 32,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 23),
                    Text('Buat akun', style: AppText.display),
                    const SizedBox(height: 10),
                    Text(
                      'Satu akun untuk rak buku, sesi membaca, dan klub bacamu.',
                      style: AppText.subtitle,
                    ),
                    const SizedBox(height: 32),
                    _field('Nama', _namaCtrl),
                    const SizedBox(height: 16),
                    _field(
                      'Email',
                      _emailCtrl,
                      tipe: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      'Kata sandi',
                      _passCtrl,
                      rahasia: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check, size: 18, color: warnaSyarat),
                        const SizedBox(width: 8),
                        Text(
                          'Minimal 8 karakter',
                          style: AppText.body.copyWith(color: warnaSyarat),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: AppSizes.buttonHeight,
                      child: FilledButton(
                        onPressed: _loading ? null : _daftar,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text('Daftar'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Profilmu dibuat otomatis setelah daftar, lalu kamu langsung diarahkan ke Beranda.',
                          textAlign: TextAlign.center,
                          style: AppText.hint,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text.rich(
                            TextSpan(
                              text: 'Sudah punya akun? ',
                              style: AppText.body,
                              children: [
                                TextSpan(
                                  text: 'Masuk',
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
