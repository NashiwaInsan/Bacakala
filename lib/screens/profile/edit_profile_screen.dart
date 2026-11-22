import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_circle.dart';

/// Halaman Ubah profil: foto dan nama.
/// Mengembalikan [Profile] terbaru lewat Navigator.pop jika berhasil disimpan.
class EditProfileScreen extends StatefulWidget {
  final Profile profil;
  const EditProfileScreen({super.key, required this.profil});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _service = ProfileService();
  final _picker = ImagePicker();
  late final TextEditingController _namaCtrl = TextEditingController(
    text: widget.profil.nama,
  );

  // Foto baru yang dipilih tapi belum diunggah (baru diunggah saat Simpan).
  Uint8List? _fotoBaru;
  String _namaFileBaru = '';
  bool _hapusFoto = false;

  bool _menyimpan = false;
  String? _error;

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  String get _inisial {
    final nama = widget.profil.nama.trim();
    return nama.isEmpty ? '?' : nama[0].toUpperCase();
  }

  /// Foto yang sedang ditampilkan (baru dipilih, atau yang tersimpan).
  bool get _adaFoto =>
      _fotoBaru != null || (!_hapusFoto && widget.profil.avatarUrl != null);

  Future<void> _pilihFoto() async {
    try {
      // Dikecilkan saat dipilih supaya unggahan ringan.
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (file == null) return; // dibatalkan
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _fotoBaru = bytes;
        _namaFileBaru = file.name;
        _hapusFoto = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Tidak bisa membuka galeri');
    }
  }

  void _hapus() {
    setState(() {
      _fotoBaru = null;
      _hapusFoto = true;
    });
  }

  String? _validasiNama() {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) return 'Nama tidak boleh kosong';
    if (nama.length > 50) return 'Nama maksimal 50 karakter';
    return null;
  }

  Future<void> _simpan() async {
    final pesan = _validasiNama();
    if (pesan != null) {
      setState(() => _error = pesan);
      return;
    }

    setState(() {
      _menyimpan = true;
      _error = null;
    });
    try {
      String? urlBaru;
      final hapus = _hapusFoto && _fotoBaru == null;
      if (_fotoBaru != null) {
        urlBaru = await _service.uploadAvatar(_fotoBaru!, _namaFileBaru);
      } else if (hapus && widget.profil.avatarUrl != null) {
        await _service.deleteAvatarFile();
      }

      final baru = await _service.updateProfile(
        nama: _namaCtrl.text,
        avatarUrl: urlBaru,
        hapusFoto: hapus,
      );
      if (mounted) Navigator.of(context).pop(baru);
    } on ServiceException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _menyimpan = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Text('Ubah profil', style: AppText.display),
              const SizedBox(height: 28),
              Center(
                child: AvatarCircle(
                  inisial: _inisial,
                  url: _hapusFoto ? null : widget.profil.avatarUrl,
                  bytes: _fotoBaru,
                  size: 96,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _menyimpan ? null : _pilihFoto,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(
                      _adaFoto ? 'Ganti foto' : 'Pilih foto',
                      style: AppText.link,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      shape: const StadiumBorder(),
                    ),
                  ),
                  if (_adaFoto) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _menyimpan ? null : _hapus,
                      child: Text(
                        'Hapus foto',
                        style: AppText.link.copyWith(color: AppColors.danger),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 28),
              Text('Nama', style: AppText.label),
              const SizedBox(height: 8),
              TextField(
                controller: _namaCtrl,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.done,
                style: AppText.input,
                onSubmitted: (_) => _menyimpan ? null : _simpan(),
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
                      : const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
