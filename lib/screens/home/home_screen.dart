import 'package:material_ui/material_ui.dart';

import '../../models/book.dart';
import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../services/book_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/book_card.dart';
import '../../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  final _profileService = ProfileService();
  final _bookService = BookService();

  bool _loading = true;
  String? _error;
  Profile? _profile;
  Book? _book;
  int _selesai = 0;

  // Sesi membaca belum dipakai, jadi sementara 0 / kosong
  final int _menitMingguIni = 0;
  final int _beruntun = 0;
  final List<bool> _hariAdaSesi = List.filled(7, false);

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Ambil semua data Beranda lewat services.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hasil = await Future.wait([
        _profileService.getMyProfile(),
        _bookService.getCurrentlyReading(),
        _bookService.countFinishedThisYear(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = hasil[0] as Profile?;
        _book = hasil[1] as Book?;
        _selesai = hasil[2] as int;
      });
    } on ServiceException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _segeraHadir() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Segera hadir')));
  }

  /// Logout lewat ketuk lama pada avatar
  Future<void> _konfirmasiKeluar() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu masuk lagi untuk membuka Beranda.'),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  // --- Helper tampilan ---

  String get _sapaan {
    const hari = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu', //
    ];
    final now = DateTime.now();
    final jam = now.hour;
    final waktu = jam >= 4 && jam <= 10
        ? 'pagi'
        : jam >= 11 && jam <= 14
        ? 'siang'
        : jam >= 15 && jam <= 17
        ? 'sore'
        : 'malam';
    return '${hari[now.weekday - 1]} $waktu, $_namaDepan';
  }

  String get _namaDepan {
    final p = _profile;
    if (p != null && p.nama.trim().isNotEmpty) return p.namaDepan;
    final email = _auth.currentUser?.email ?? '';
    return email.isNotEmpty ? email.split('@').first : 'kamu';
  }

  String get _inisial => _namaDepan.isEmpty ? '?' : _namaDepan[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 4) {
            Navigator.pushNamed(context, '/profile');
          } else if (i != 0) {
            _segeraHadir();
          }
        },
      ),
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
    // Loading pertama kali
    if (_loading && _profile == null && _book == null && _error == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      );
    }

    // Gagal memuat: pesan ramah + tombol coba lagi (tetap bisa tarik untuk refresh)
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

    final target = (_profile?.targetTahunan ?? 0) > 0
        ? _profile!.targetTahunan!
        : 12; // target 0/null -> 12

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 21, 24, 24),
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        BookCard(book: _book, onContinue: _segeraHadir),
        const SizedBox(height: 16),
        _buildTarget(target),
        const SizedBox(height: 16),
        _buildStatRow(),
        const SizedBox(height: 16),
        _buildWeek(),
      ],
    );
  }

  Widget _buildHeader() {
    final judul = _book == null
        ? 'Yuk mulai\nbuku pertamamu.'
        : 'Halaman ${_book!.halamanTerakhir}\nmasih menunggumu.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_sapaan, style: AppText.greeting),
              const SizedBox(height: 2),
              Text(judul, style: AppText.homeTitle),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Ketuk lama untuk keluar
        GestureDetector(
          onLongPress: _konfirmasiKeluar,
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(_inisial, style: AppText.avatar),
          ),
        ),
      ],
    );
  }

  BoxDecoration _kartu([Color warna = AppColors.card, bool border = true]) {
    return BoxDecoration(
      color: warna,
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      border: border ? Border.all(color: AppColors.border) : null,
    );
  }

  Widget _buildTarget(int target) {
    return Container(
      padding: const EdgeInsets.fromLTRB(19, 30, 19, 19),
      decoration: _kartu(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$_selesai', style: AppText.bigNumberGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text('dari $target buku tahun ini', style: AppText.body),
              ),
              Text('Target ${DateTime.now().year}', style: AppText.hintStrong),
            ],
          ),
          const SizedBox(height: 14),
          _TargetShelf(target: target, selesai: _selesai),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 96,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            decoration: _kartu(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Minggu ini', style: AppText.body),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$_menitMingguIni', style: AppText.bigNumber),
                    const SizedBox(width: 6),
                    Text('menit', style: AppText.body),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 96,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            decoration: _kartu(AppColors.yellowSoft, false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_outlined,
                      size: 18,
                      color: AppColors.brown,
                    ),
                    const SizedBox(width: 6),
                    Text('Beruntun', style: AppText.brownLabel),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$_beruntun', style: AppText.bigNumberBrown),
                    const SizedBox(width: 6),
                    Text('hari', style: AppText.brownUnit),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeek() {
    const label = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final hariIni = DateTime.now().weekday - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          Column(
            children: [
              _lingkaranHari(ada: _hariAdaSesi[i], hariIni: i == hariIni),
              const SizedBox(height: 6),
              Text(
                label[i],
                style: i == hariIni ? AppText.dayLabelToday : AppText.dayLabel,
              ),
            ],
          ),
      ],
    );
  }

  Widget _lingkaranHari({required bool ada, required bool hariIni}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ada ? AppColors.primary : AppColors.card,
        border: Border.all(
          // Hari ini diberi ring gelap
          color: hariIni
              ? AppColors.textPrimary
              : (ada ? AppColors.primary : AppColors.border),
          width: hariIni ? 2.5 : 1.5,
        ),
      ),
      child: ada
          ? const Icon(Icons.check, size: 20, color: AppColors.white)
          : null,
    );
  }
}

/// Deretan punggung buku sejumlah target: selesai berwarna, sisanya putus-putus.
class _TargetShelf extends StatelessWidget {
  final int target;
  final int selesai;
  const _TargetShelf({required this.target, required this.selesai});

  static const _tinggi = [
    37.0,
    31.0,
    40.0,
    34.0,
    32.0,
    39.0,
    31.0,
    37.0,
    41.0,
    32.0,
    33.0,
    39.0,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const jarak = 6.0;
        // Lebar maksimum 20; menyempit otomatis jika target besar
        final lebar = ((c.maxWidth - jarak * (target - 1)) / target).clamp(
          4.0,
          20.0,
        );

        return SizedBox(
          height: 42,
          child: Row(
            mainAxisAlignment: target <= 12
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < target; i++)
                Padding(
                  padding: EdgeInsets.only(
                    right: (target > 12 && i < target - 1) ? jarak : 0,
                  ),
                  child: i < selesai
                      ? Container(
                          width: lebar,
                          height: _tinggi[i % _tinggi.length],
                          decoration: BoxDecoration(
                            color:
                                AppColors.finishedSpines[i %
                                    AppColors.finishedSpines.length],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      : CustomPaint(
                          size: Size(lebar, _tinggi[i % _tinggi.length]),
                          painter: _DashedBoxPainter(),
                        ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Kotak bergaris putus-putus abu-abu.
class _DashedBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textHint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
      );

    // Potong path menjadi dash pendek
    for (final metric in path.computeMetrics()) {
      double jarak = 0;
      while (jarak < metric.length) {
        canvas.drawPath(metric.extractPath(jarak, jarak + 4), paint);
        jarak += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
