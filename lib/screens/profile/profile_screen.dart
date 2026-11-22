import 'package:material_ui/material_ui.dart';

import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../services/book_service.dart';
import '../../services/profile_service.dart';
import '../../services/reminder_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'reminder_screen.dart';

/// Halaman Profil: data akun, target tahunan, ubah nama, tentang, dan keluar.
class ProfileScreen extends StatefulWidget {
  /// true hanya untuk pemakaian sementara sebelum main_shell (5 tab) di-merge.
  /// Di dalam main_shell, pakai `const ProfileScreen()` karena navbar sudah ada.
  final bool showBottomNav;
  const ProfileScreen({super.key, this.showBottomNav = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _profileService = ProfileService();
  final _bookService = BookService();

  bool _loading = true;
  String? _error;
  Profile? _profile;
  int _selesai = 0;
  ReadingSummary? _ringkasan;
  ReminderSetting? _pengingat;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Ambil data Profil lewat services.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profil = await _profileService.getMyProfile();

      // Jumlah buku selesai hanya pelengkap kartu target. Kalau gagal,
      // profil tetap tampil dengan angka 0.
      var selesai = 0;
      try {
        selesai = await _bookService.countFinishedThisYear();
      } on ServiceException {
        selesai = 0;
      }

      // Ringkasan per status juga pelengkap: kalau gagal, barisnya disembunyikan.
      ReadingSummary? ringkasan;
      try {
        ringkasan = await _profileService.getReadingSummary();
      } on ServiceException {
        ringkasan = null;
      }

      final pengingat = await ReminderService().muat();

      if (!mounted) return;
      setState(() {
        _profile = profil;
        _selesai = selesai;
        _ringkasan = ringkasan;
        _pengingat = pengingat;
      });
    } on ServiceException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  // --- Data turunan untuk tampilan ---

  String get _nama {
    final p = _profile;
    if (p != null && p.nama.trim().isNotEmpty) return p.nama.trim();
    final email = _auth.currentUser?.email ?? '';
    return email.isNotEmpty ? email.split('@').first : 'Pembaca';
  }

  String get _email {
    final p = _profile;
    if (p != null && p.email.isNotEmpty) return p.email;
    return _auth.currentUser?.email ?? '';
  }

  String get _inisial => _nama.isEmpty ? '?' : _nama[0].toUpperCase();

  /// Sama dengan Beranda: target kosong/0 dianggap 12.
  int get _target {
    final t = _profile?.targetTahunan ?? 0;
    return t > 0 ? t : 12;
  }

  /// Contoh: "4 selesai · 2 sedang dibaca · 1 di daftar tunggu".
  /// Kalau ringkasan gagal dimuat, dipakai teks sederhana dari angka target.
  String get _teksRingkasan {
    final r = _ringkasan;
    if (r == null) return '$_selesai dari $_target buku selesai';
    return '${r.selesai} selesai · ${r.sedangDibaca} sedang dibaca · '
        '${r.inginDibaca} di daftar tunggu';
  }

  String? get _membacaSejak {
    final dibuat = DateTime.tryParse(_auth.currentUser?.createdAt ?? '');
    if (dibuat == null) return null;
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final lokal = dibuat.toLocal();
    return 'Membaca sejak ${bulan[lokal.month - 1]} ${lokal.year}';
  }

  // --- Aksi ---

  Future<bool> _bukaSheet(_EditSheet sheet) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusCard),
        ),
      ),
      builder: (_) => sheet,
    );
    return ok == true;
  }

  Future<void> _ubahProfil() async {
    final profil = _profile;
    if (profil == null) return;
    final baru = await Navigator.of(context).push<Profile>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(profil: profil)),
    );
    if (baru != null && mounted) {
      setState(() => _profile = baru);
      _snack('Profil diperbarui');
    }
  }

  Future<void> _ubahTarget() async {
    final tersimpan = await _bukaSheet(
      _EditSheet(
        judul: 'Ubah target ${DateTime.now().year}',
        label: 'Jumlah buku',
        nilaiAwal: '$_target',
        keyboardType: TextInputType.number,
        validator: (v) {
          final angka = int.tryParse(v.trim());
          if (angka == null || angka < 1 || angka > 100) {
            return 'Isi angka 1 sampai 100';
          }
          return null;
        },
        onSave: (v) async {
          final baru = await _profileService.updateProfile(
            targetTahunan: int.parse(v.trim()),
          );
          if (mounted) setState(() => _profile = baru);
        },
      ),
    );
    if (tersimpan && mounted) _snack('Target diperbarui');
  }

  Future<void> _aturPengingat() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const ReminderScreen()),
    );
    // Muat ulang agar subjudul menu sesuai pengaturan terbaru.
    final pengingat = await ReminderService().muat();
    if (mounted) setState(() => _pengingat = pengingat);
  }

  /// Subjudul menu Pengingat: "Setiap hari, 19.30", "Mati", atau keterangan
  /// bahwa fitur ini hanya untuk Android (misalnya saat dibuka di browser).
  String get _subjudulPengingat {
    if (!ReminderService.didukung) return 'Tersedia di aplikasi Android';
    final p = _pengingat;
    if (p == null || !p.aktif) return 'Mati';
    return 'Setiap hari, ${ReminderService.formatJam(p.jam, p.menit)}';
  }

  Future<void> _gantiKataSandi() async {
    final berhasil = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
    if (berhasil == true && mounted) _snack('Kata sandi diperbarui');
  }

  Future<void> _tentang() {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tentang Bacakala'),
        content: const Text(
          'Pelacak kebiasaan membaca.\n'
          'Versi 0.1 · Kelompok 4\n'
          'Teknologi Berkembang 2026/2027',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _konfirmasiKeluar() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu masuk lagi untuk membuka Bacakala.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    try {
      await _auth.signOut();
    } on ServiceException catch (e) {
      if (!mounted) return;
      _snack(e.message);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  void _onNavTap(int i) {
    if (i == 0) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } else if (i == 1) {
      // Ganti halaman, bukan menumpuk: tumpukan tetap [Beranda, tab].
      Navigator.of(context).pushReplacementNamed('/rak');
    } else if (i != 4) {
      _snack('Segera hadir');
    }
  }

  // --- Tampilan ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavBar(currentIndex: 4, onTap: _onNavTap)
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _profile == null && _error == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: AppText.bodyStrong),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _load,
              child: Text('Coba lagi', style: AppText.link),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _konfirmasiKeluar,
              child: Text(
                'Keluar dari akun',
                style: AppText.link.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 21, 24, 24),
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildTarget(),
        const SizedBox(height: 16),
        _buildMenu(),
        const SizedBox(height: 20),
        _buildKeluar(),
      ],
    );
  }

  BoxDecoration get _kartu => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
    border: Border.all(color: AppColors.border),
  );

  Widget _buildHeader() {
    final sejak = _membacaSejak;
    return Row(
      children: [
        AvatarCircle(inisial: _inisial, url: _profile?.avatarUrl, size: 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_nama, style: AppText.bookTitle),
              const SizedBox(height: 2),
              Text(_email, style: AppText.caption),
              if (sejak != null) Text(sejak, style: AppText.hint),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTarget() {
    final progres = (_selesai / _target).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: _kartu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target ${DateTime.now().year}',
                      style: AppText.hintStrong,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$_target', style: AppText.bigNumber),
                        const SizedBox(width: 6),
                        Text('buku', style: AppText.body),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _ubahTarget,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text('Ubah', style: AppText.link),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progres,
              minHeight: 8,
              backgroundColor: AppColors.primarySoft,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(_teksRingkasan, style: AppText.caption),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return Container(
      decoration: _kartu,
      child: Column(
        children: [
          _menuItem(
            icon: Icons.person_outline,
            judul: 'Ubah profil',
            subjudul: 'Nama dan foto',
            onTap: _ubahProfil,
          ),
          const Divider(height: 1, color: AppColors.border),
          _menuItem(
            icon: Icons.notifications_none,
            judul: 'Pengingat membaca',
            subjudul: _subjudulPengingat,
            onTap: _aturPengingat,
          ),
          const Divider(height: 1, color: AppColors.border),
          _menuItem(
            icon: Icons.key_outlined,
            judul: 'Ganti kata sandi',
            onTap: _gantiKataSandi,
          ),
          const Divider(height: 1, color: AppColors.border),
          _menuItem(
            icon: Icons.info_outline,
            judul: 'Tentang Bacakala',
            subjudul: 'Versi 0.1 · Kelompok 4',
            onTap: _tentang,
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String judul,
    String? subjudul,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: AppText.bodyStrong),
                  if (subjudul != null) Text(subjudul, style: AppText.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildKeluar() {
    return OutlinedButton.icon(
      onPressed: _konfirmasiKeluar,
      icon: const Icon(Icons.logout, color: AppColors.danger),
      label: Text(
        'Keluar',
        style: AppText.button.copyWith(color: AppColors.danger),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusField),
        ),
      ),
    );
  }
}

/// Bottom sheet isian satu kolom (dipakai untuk ubah nama dan ubah target).
/// Sheet tetap terbuka dan menampilkan pesan jika penyimpanan gagal.
class _EditSheet extends StatefulWidget {
  final String judul;
  final String label;
  final String nilaiAwal;
  final TextInputType keyboardType;
  final String? Function(String) validator;
  final Future<void> Function(String) onSave;

  const _EditSheet({
    required this.judul,
    required this.label,
    required this.nilaiAwal,
    required this.keyboardType,
    required this.validator,
    required this.onSave,
  });

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.nilaiAwal,
  );
  String? _error;
  bool _menyimpan = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final pesan = widget.validator(_controller.text);
    if (pesan != null) {
      setState(() => _error = pesan);
      return;
    }
    setState(() {
      _menyimpan = true;
      _error = null;
    });
    try {
      await widget.onSave(_controller.text);
      if (mounted) Navigator.pop(context, true);
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        12,
        AppSizes.screenPadding,
        MediaQuery.of(context).viewInsets.bottom + AppSizes.screenPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(widget.judul, style: AppText.bookTitle),
          const SizedBox(height: 16),
          Text(widget.label, style: AppText.label),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: widget.keyboardType,
            textInputAction: TextInputAction.done,
            style: AppText.input,
            onSubmitted: (_) => _simpan(),
            decoration: InputDecoration(errorText: _error),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _menyimpan ? null : _simpan,
            child: _menyimpan
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}