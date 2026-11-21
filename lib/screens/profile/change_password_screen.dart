import 'package:material_ui/material_ui.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Halaman Ganti kata sandi: kata sandi lama, baru, dan konfirmasi.
/// Mengembalikan `true` lewat Navigator.pop jika berhasil disimpan.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _auth = AuthService();
  final _lamaCtrl = TextEditingController();
  final _baruCtrl = TextEditingController();
  final _konfirmasiCtrl = TextEditingController();

  bool _lihatLama = false;
  bool _lihatBaru = false;
  bool _lihatKonfirmasi = false;
  bool _menyimpan = false;
  String? _error;

  // Indikator "Minimal 8 karakter" berubah langsung saat mengetik,
  // sama seperti di halaman Register.
  bool get _baruCukup => _baruCtrl.text.length >= 8;

  @override
  void dispose() {
    _lamaCtrl.dispose();
    _baruCtrl.dispose();
    _konfirmasiCtrl.dispose();
    super.dispose();
  }

  /// Kembalikan pesan kesalahan, atau null jika isian sudah benar.
  String? _validasi() {
    if (_lamaCtrl.text.isEmpty) return 'Kata sandi lama wajib diisi';
    if (_baruCtrl.text.length < 8) return 'Kata sandi baru minimal 8 karakter';
    if (_baruCtrl.text == _lamaCtrl.text) {
      return 'Kata sandi baru harus berbeda dari yang lama';
    }
    if (_konfirmasiCtrl.text != _baruCtrl.text) {
      return 'Konfirmasi kata sandi tidak sama';
    }
    return null;
  }

  Future<void> _simpan() async {
    final pesan = _validasi();
    if (pesan != null) {
      setState(() => _error = pesan);
      return;
    }

    setState(() {
      _menyimpan = true;
      _error = null;
    });
    try {
      await _auth.changePassword(_lamaCtrl.text, _baruCtrl.text);
      if (mounted) Navigator.of(context).pop(true);
    } on ServiceException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _menyimpan = false;
        });
      }
    }
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required bool terlihat,
    required VoidCallback onToggle,
    TextInputAction aksi = TextInputAction.next,
    ValueChanged<String>? onChanged,
    VoidCallback? onSubmit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: !terlihat,
          textInputAction: aksi,
          style: AppText.input,
          onChanged: onChanged,
          onSubmitted: onSubmit == null ? null : (_) => onSubmit(),
          decoration: InputDecoration(
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                terlihat
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textHint,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final warnaSyarat = _baruCukup ? AppColors.primary : AppColors.textHint;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            8,
            AppSizes.screenPadding,
            AppSizes.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(-12, 0),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 32,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Ganti kata sandi', style: AppText.display),
              const SizedBox(height: 10),
              Text(
                'Masukkan kata sandi lamamu, lalu pilih yang baru.',
                style: AppText.subtitle,
              ),
              const SizedBox(height: 28),
              _field(
                label: 'Kata sandi lama',
                ctrl: _lamaCtrl,
                terlihat: _lihatLama,
                onToggle: () => setState(() => _lihatLama = !_lihatLama),
              ),
              const SizedBox(height: 16),
              _field(
                label: 'Kata sandi baru',
                ctrl: _baruCtrl,
                terlihat: _lihatBaru,
                onToggle: () => setState(() => _lihatBaru = !_lihatBaru),
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
              const SizedBox(height: 16),
              _field(
                label: 'Ulangi kata sandi baru',
                ctrl: _konfirmasiCtrl,
                terlihat: _lihatKonfirmasi,
                onToggle: () =>
                    setState(() => _lihatKonfirmasi = !_lihatKonfirmasi),
                aksi: TextInputAction.done,
                onSubmit: _menyimpan ? null : _simpan,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: AppText.body.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: FilledButton(
                  onPressed: _menyimpan ? null : _simpan,
                  child: _menyimpan
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Simpan kata sandi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
