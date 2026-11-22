import 'dart:typed_data';

import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../models/book.dart';
import '../../services/auth_service.dart';
import '../../services/book_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dashed_border.dart';
import 'rak_screen.dart' show statusRak;

/// Hasil layar Tambah buku lewat Navigator.pop.
/// [sampulGagal] true jika buku tersimpan tapi sampulnya gagal diunggah.
typedef TambahBukuHasil = ({Book buku, bool sampulGagal});

/// Form menambah buku baru ke rak.
class TambahBukuScreen extends StatefulWidget {
  const TambahBukuScreen({super.key});

  @override
  State<TambahBukuScreen> createState() => _TambahBukuScreenState();
}

class _TambahBukuScreenState extends State<TambahBukuScreen> {
  final _service = BookService();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _judulCtrl = TextEditingController();
  final _penulisCtrl = TextEditingController();
  final _jumlahCtrl = TextEditingController();
  final _terakhirCtrl = TextEditingController(text: '0');

  String _status = 'ingin_dibaca';

  // Sampul yang dipilih. Baru diunggah saat Simpan.
  Uint8List? _sampul;
  String _extSampul = 'jpg';
  // Tautan sampul yang sudah terunggah, supaya tidak diunggah ulang jika
  // penyimpanan buku gagal lalu dicoba lagi.
  String? _urlSampul;

  bool _menyimpan = false;
  AutovalidateMode _validasi = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _jumlahCtrl.addListener(_sinkronHalamanTerakhir);
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _penulisCtrl.dispose();
    _jumlahCtrl.dispose();
    _terakhirCtrl.dispose();
    super.dispose();
  }

  /// Status Selesai: halaman terakhir selalu sama dengan jumlah halaman.
  void _sinkronHalamanTerakhir() {
    if (_status == 'selesai') _terakhirCtrl.text = _jumlahCtrl.text.trim();
  }

  void _ubahStatus(String status) {
    setState(() {
      _status = status;
      if (status == 'ingin_dibaca') _terakhirCtrl.text = '0';
      if (status == 'selesai') _terakhirCtrl.text = _jumlahCtrl.text.trim();
    });
  }

  void _snack(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  // --- Sampul ---

  Future<void> _pilihSampul() async {
    final bisaKamera = _picker.supportsImageSource(ImageSource.camera);

    // Langsung ke galeri jika tidak ada pilihan lain.
    var aksi = 'galeri';
    if (bisaKamera || _sampul != null) {
      final dipilih = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.card,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('Pilih dari galeri', style: AppText.bodyStrong),
                onTap: () => Navigator.pop(context, 'galeri'),
              ),
              if (bisaKamera)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text('Ambil foto', style: AppText.bodyStrong),
                  onTap: () => Navigator.pop(context, 'kamera'),
                ),
              if (_sampul != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  title: Text(
                    'Hapus sampul',
                    style: AppText.bodyStrong.copyWith(color: AppColors.danger),
                  ),
                  onTap: () => Navigator.pop(context, 'hapus'),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (dipilih == null) return;
      aksi = dipilih;
    }

    if (aksi == 'hapus') {
      setState(() {
        _sampul = null;
        _urlSampul = null;
      });
      return;
    }

    try {
      // Dikecilkan saat dipilih supaya unggahan ringan.
      final file = await _picker.pickImage(
        source: aksi == 'kamera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file == null) return; // dibatalkan
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _sampul = bytes;
        _extSampul = _ekstensi(file);
        _urlSampul = null;
      });
    } catch (_) {
      if (mounted) _snack('Tidak bisa membuka gambar');
    }
  }

  /// Ekstensi gambar dari nama file (atau tipe MIME), default `jpg`.
  String _ekstensi(XFile file) {
    final nama = file.name.toLowerCase();
    final titik = nama.lastIndexOf('.');
    var ext = titik >= 0 ? nama.substring(titik + 1) : '';
    if (ext.isEmpty) {
      final mime = file.mimeType ?? '';
      ext = mime.contains('/') ? mime.split('/').last : '';
    }
    if (ext == 'jpeg') ext = 'jpg';
    return const {'jpg', 'png', 'webp', 'gif'}.contains(ext) ? ext : 'jpg';
  }

  // --- Validasi ---

  String? _wajib(String? v, String nama) =>
      (v == null || v.trim().isEmpty) ? '$nama wajib diisi' : null;

  String? _validasiJumlah(String? v) {
    final teks = v?.trim() ?? '';
    if (teks.isEmpty) return 'Wajib diisi';
    final n = int.tryParse(teks);
    if (n == null || n <= 0) return 'Harus lebih dari 0';
    return null;
  }

  String? _validasiTerakhir(String? v) {
    // Ingin dibaca & Selesai diisi otomatis.
    if (_status != 'sedang_dibaca') return null;
    final teks = v?.trim() ?? '';
    if (teks.isEmpty) return 'Wajib diisi';
    final n = int.tryParse(teks);
    if (n == null || n < 0) return 'Harus berupa angka';
    final total = int.tryParse(_jumlahCtrl.text.trim());
    if (total != null && total > 0 && n > total) return 'Maksimal $total';
    return null;
  }

  // --- Simpan ---

  Future<void> _simpan() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _validasi = AutovalidateMode.always);
      return;
    }

    final total = int.parse(_jumlahCtrl.text.trim());
    final terakhir = switch (_status) {
      'ingin_dibaca' => 0,
      'selesai' => total,
      _ => int.parse(_terakhirCtrl.text.trim()),
    };

    setState(() => _menyimpan = true);

    // Sampul gagal tidak membatalkan penyimpanan buku.
    var sampulGagal = false;
    if (_sampul != null && _urlSampul == null) {
      try {
        _urlSampul = await _service.uploadCover(_sampul!, _extSampul);
      } on ServiceException {
        sampulGagal = true;
      }
    }

    try {
      final buku = await _service.addBook(
        judul: _judulCtrl.text,
        penulis: _penulisCtrl.text,
        totalHalaman: total,
        halamanTerakhir: terakhir,
        status: _status,
        coverUrl: _urlSampul,
      );
      if (!mounted) return;
      final TambahBukuHasil hasil = (buku: buku, sampulGagal: sampulGagal);
      Navigator.of(context).pop(hasil);
    } on ServiceException catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      _snack(e.message);
    }
  }

  // --- Tampilan ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Tutup',
          onPressed: _menyimpan ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 28, color: AppColors.textPrimary),
        ),
        titleSpacing: 4,
        title: Text('Tambah buku', style: AppText.appBarTitle),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            8,
            AppSizes.screenPadding,
            16,
          ),
          child: SizedBox(
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
                  : const Text('Simpan ke rak'),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _validasi,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            12,
            AppSizes.screenPadding,
            AppSizes.screenPadding,
          ),
          children: [
            _buildSampul(),
            const SizedBox(height: 24),
            _label('Judul'),
            TextFormField(
              controller: _judulCtrl,
              enabled: !_menyimpan,
              style: AppText.input,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (v) => _wajib(v, 'Judul'),
            ),
            const SizedBox(height: 20),
            _label('Penulis'),
            TextFormField(
              controller: _penulisCtrl,
              enabled: !_menyimpan,
              style: AppText.input,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) => _wajib(v, 'Penulis'),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Jumlah halaman'),
                      _fieldAngka(
                        _jumlahCtrl,
                        enabled: !_menyimpan,
                        validator: _validasiJumlah,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Halaman terakhir'),
                      _fieldAngka(
                        _terakhirCtrl,
                        // Ingin dibaca = 0, Selesai = jumlah halaman (otomatis)
                        enabled: _status == 'sedang_dibaca' && !_menyimpan,
                        validator: _validasiTerakhir,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _label('Status'),
            _buildStatus(),
          ],
        ),
      ),
    );
  }

  Widget _label(String teks) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(teks, style: AppText.label),
  );

  Widget _fieldAngka(
    TextEditingController ctrl, {
    required bool enabled,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      style: enabled
          ? AppText.input
          : AppText.input.copyWith(color: AppColors.textHint),
      decoration: const InputDecoration(errorMaxLines: 2),
      validator: validator,
    );
  }

  Widget _buildSampul() {
    return Row(
      children: [
        Semantics(
          button: true,
          label: _sampul == null ? 'Pilih sampul' : 'Ganti sampul',
          child: GestureDetector(
            onTap: _menyimpan ? null : _pilihSampul,
            child: SizedBox(
              width: 104,
              height: 156,
              child: _sampul != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_sampul!, fit: BoxFit.cover),
                    )
                  : CustomPaint(
                      foregroundPainter: const DashedBorderPainter(
                        color: AppColors.textHint,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.photo_camera_outlined,
                              size: 30,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 6),
                            Text('Sampul', style: AppText.caption),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sampul (opsional)', style: AppText.bodyStrong),
              const SizedBox(height: 6),
              Text(
                'Foto sampul atau pilih dari galeri. Kalau kosong, kami '
                'buatkan sampul polos dari judulnya.',
                style: AppText.caption.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatus() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusField),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          for (final (nilai, label) in statusRak)
            Expanded(child: _segmen(nilai, label)),
        ],
      ),
    );
  }

  Widget _segmen(String nilai, String label) {
    final aktif = nilai == _status;
    final radius = BorderRadius.circular(12);
    return Semantics(
      selected: aktif,
      button: true,
      child: InkWell(
        borderRadius: radius,
        onTap: _menyimpan ? null : () => _ubahStatus(nilai),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: aktif ? AppColors.primarySoft : Colors.transparent,
            borderRadius: radius,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: aktif ? AppText.tabActive : AppText.tabInactive,
            ),
          ),
        ),
      ),
    );
  }
}
