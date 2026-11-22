import 'package:material_ui/material_ui.dart';

import '../../models/book.dart';
import '../../services/auth_service.dart';
import '../../services/book_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/bottom_nav_bar.dart';

/// Status buku di rak: (nilai di database, label di layar).
const statusRak = <(String, String)>[
  ('ingin_dibaca', 'Ingin dibaca'),
  ('sedang_dibaca', 'Sedang dibaca'),
  ('selesai', 'Selesai'),
];

/// Layar Rak Buku: semua buku milik user, dikelompokkan per status.
class RakScreen extends StatefulWidget {
  const RakScreen({super.key});

  @override
  State<RakScreen> createState() => _RakScreenState();
}

class _RakScreenState extends State<RakScreen> {
  final _service = BookService();
  final _cariCtrl = TextEditingController();

  List<Book> _buku = [];
  bool _loading = true;
  String? _error;
  int _tab = 1; // default: Sedang dibaca
  String _kataCari = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cariCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final buku = await _service.getAllBooks();
      if (!mounted) return;
      setState(() => _buku = buku);
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

  Future<void> _bukaTambah() async {
    final hasil = await Navigator.of(context).pushNamed('/rak/tambah');
    if (hasil == null || !mounted) return;
    await _load();
  }

  void _onNavTap(int i) {
    switch (i) {
      case 0:
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      case 1:
        break; // sudah di Rak
      case 4:
        Navigator.of(context).pushReplacementNamed('/profile');
      default:
        _snack('Segera hadir');
    }
  }

  // --- Data turunan ---

  int _jumlah(String status) => _buku.where((b) => b.status == status).length;

  List<Book> get _bukuTampil {
    final status = statusRak[_tab].$1;
    return _buku
        .where(
          (b) =>
              b.status == status &&
              (_kataCari.isEmpty || b.judul.toLowerCase().contains(_kataCari)),
        )
        .toList();
  }

  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', //
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  /// Mis. "2 Nov", atau "2 Nov 2025" jika bukan tahun ini.
  static String _tanggalSingkat(DateTime t) {
    final lokal = t.toLocal();
    final teks = '${lokal.day} ${_bulan[lokal.month - 1]}';
    return lokal.year == DateTime.now().year ? teks : '$teks ${lokal.year}';
  }

  String _keterangan(Book b) {
    switch (b.status) {
      case 'selesai':
        final t = b.tanggalSelesaiTampil;
        return t == null ? 'Selesai' : 'Selesai ${_tanggalSingkat(t)}';
      case 'sedang_dibaca':
        return 'Hal. ${b.halamanTerakhir} / ${b.totalHalaman} · ${b.persen}%';
      default:
        return b.penulis;
    }
  }

  // --- Tampilan ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(currentIndex: 1, onTap: _onNavTap),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bukaTambah,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        icon: const Icon(Icons.add, size: 26),
        label: Text('Tambah buku', style: AppText.button),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                21,
                AppSizes.screenPadding,
                0,
              ),
              child: _buildHeader(),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding,
              ),
              child: _buildCari(),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding,
              ),
              child: _buildTab(),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: _buildIsi(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text('Rak Buku', style: AppText.display)),
        if (!_loading || _buku.isNotEmpty)
          Text('${_buku.length} buku', style: AppText.body),
      ],
    );
  }

  OutlineInputBorder _pil(Color warna) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(100),
    borderSide: BorderSide(color: warna, width: 1.5),
  );

  Widget _buildCari() {
    return TextField(
      controller: _cariCtrl,
      style: AppText.input,
      textInputAction: TextInputAction.search,
      onChanged: (v) => setState(() => _kataCari = v.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Cari judul buku',
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 10),
          child: Icon(Icons.search, size: 24, color: AppColors.textSecondary),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        suffixIcon: _kataCari.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () {
                  _cariCtrl.clear();
                  setState(() => _kataCari = '');
                },
              ),
        border: _pil(AppColors.border),
        enabledBorder: _pil(AppColors.border),
        focusedBorder: _pil(AppColors.primary),
      ),
    );
  }

  Widget _buildTab() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < statusRak.length; i++)
            Expanded(child: _tabItem(i)),
        ],
      ),
    );
  }

  Widget _tabItem(int i) {
    final aktif = i == _tab;
    final (status, label) = statusRak[i];
    return InkWell(
      onTap: () => setState(() => _tab = i),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Center(
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: label,
                          style: aktif
                              ? AppText.tabActive
                              : AppText.tabInactive,
                        ),
                        TextSpan(
                          text: '  ${_jumlah(status)}',
                          style: aktif ? AppText.tabActive : AppText.tabCount,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: aktif ? AppColors.primary : Colors.transparent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Daftar yang bisa ditarik untuk refresh, berisi [children] di tengah.
  Widget _pesan(List<Widget> children) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        72,
        AppSizes.screenPadding,
        AppSizes.screenPadding,
      ),
      children: children,
    );
  }

  Widget _buildIsi() {
    if (_loading && _buku.isEmpty && _error == null) {
      return _pesan(const [
        SizedBox(height: 60),
        Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ]);
    }

    if (_error != null) {
      return _pesan([
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
      ]);
    }

    if (_jumlah(statusRak[_tab].$1) == 0) {
      return _pesan([
        const Icon(
          Icons.auto_stories_outlined,
          size: 44,
          color: AppColors.textHint,
        ),
        const SizedBox(height: 12),
        Text(
          'Belum ada buku di rak ini',
          textAlign: TextAlign.center,
          style: AppText.bodyStrong,
        ),
        const SizedBox(height: 4),
        Text(
          'Tambahkan buku supaya rakmu mulai terisi.',
          textAlign: TextAlign.center,
          style: AppText.caption,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: _bukaTambah,
            icon: const Icon(Icons.add, color: AppColors.primary),
            label: Text('Tambah buku', style: AppText.link),
          ),
        ),
      ]);
    }

    final buku = _bukuTampil;
    if (buku.isEmpty) {
      return _pesan([
        const Icon(Icons.search_off, size: 44, color: AppColors.textHint),
        const SizedBox(height: 12),
        Text(
          'Tidak ada judul yang cocok',
          textAlign: TextAlign.center,
          style: AppText.bodyStrong,
        ),
      ]);
    }

    // Grid 3 kolom dibuat per baris supaya tinggi item mengikuti isinya
    // (judul 1 atau 2 baris) dan tidak overflow.
    const kolom = 3;
    final jumlahBaris = (buku.length / kolom).ceil();
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      // Ruang bawah supaya baris terakhir tidak tertutup tombol Tambah buku
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        20,
        AppSizes.screenPadding,
        100,
      ),
      itemCount: jumlahBaris,
      itemBuilder: (context, baris) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < kolom; j++) ...[
                if (j > 0) const SizedBox(width: 16),
                Expanded(
                  child: baris * kolom + j < buku.length
                      ? _itemBuku(buku[baris * kolom + j])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _itemBuku(Book b) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookCover(
          book: b,
          onTap: () {
            // TODO: buka detail buku (di luar cakupan PRD rak buku)
          },
        ),
        const SizedBox(height: 10),
        Text(
          b.judul,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.gridTitle,
        ),
        const SizedBox(height: 3),
        Text(
          _keterangan(b),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.gridCaption,
        ),
      ],
    );
  }
}
