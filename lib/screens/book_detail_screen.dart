import 'package:material_ui/material_ui.dart';

import '../../models/book.dart';
import '../../services/auth_service.dart';
import '../../services/book_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/progress_bar.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;

  /// Opsional: data awal agar tampilan langsung muncul sambil memuat data terbaru.
  final Book? initialBook;

  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.initialBook,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _bookService = BookService();

  Book? _book;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _book = widget.initialBook;
    _loadBook();
  }

  Future<void> _loadBook() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _bookService.getBookById(widget.bookId);
      if (!mounted) return;
      setState(() => _book = data);
    } on ServiceException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _segeraHadir() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Sesi membaca segera hadir')));
  }

  String _labelStatus(String status) {
    switch (status) {
      case 'sedang_dibaca':
        return 'Sedang Dibaca';
      case 'selesai':
        return 'Selesai';
      default:
        return 'Ingin Dibaca';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Detail Buku', style: AppText.bodyStrong),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Loading awal jika belum ada data sama sekali
    if (_loading && _book == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Error jika gagal memuat dan tidak ada data awal
    if (_error != null && _book == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppText.bodyStrong,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadBook,
                child: Text('Coba lagi', style: AppText.link),
              ),
            ],
          ),
        ),
      );
    }

    final book = _book!;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBookHeader(book),
                const SizedBox(height: 20),
                _buildProgressCard(book),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _segeraHadir,
                    icon: const Icon(Icons.menu_book_rounded, size: 20),
                    label: Text(
                      book.halamanTerakhir > 0
                          ? 'Lanjutkan Membaca'
                          : 'Mulai Membaca',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textHint,
              indicatorColor: AppColors.primary,
              labelStyle: AppText.bodyStrong,
              tabs: const [
                Tab(text: 'Riwayat'),
                Tab(text: 'Catatan'),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        children: [
          _buildEmptyTab(
            icon: Icons.history_rounded,
            judul: 'Belum ada riwayat membaca',
            deskripsi: 'Riwayat sesi membacamu untuk buku ini akan muncul di sini.',
          ),
          _buildEmptyTab(
            icon: Icons.edit_note_rounded,
            judul: 'Belum ada catatan',
            deskripsi: 'Simpan kutipan atau pemikiran penting saat membaca buku ini.',
          ),
        ],
      ),
    );
  }

  Widget _buildBookHeader(Book book) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover Buku
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 100,
            height: 145,
            color: AppColors.primarySoft,
            child: book.coverUrl != null
                ? Image.network(
                    book.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _coverPlaceholder(),
                  )
                : _coverPlaceholder(),
          ),
        ),
        const SizedBox(width: 16),
        // Info Buku
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _labelStatus(book.status),
                  style: AppText.hintStrong.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                book.judul,
                style: AppText.bodyStrong.copyWith(fontSize: 18),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                book.penulis,
                style: AppText.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                '${book.totalHalaman} halaman',
                style: AppText.hintStrong,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _coverPlaceholder() {
    return const Center(
      child: Icon(
        Icons.book_outlined,
        size: 36,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildProgressCard(Book book) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progres Membaca', style: AppText.bodyStrong),
              Text(
                '${book.persen}%',
                style: AppText.bodyStrong.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Pakai ulang widgets/progress_bar.dart
          ProgressBar(value: book.progres, height: 8),
          const SizedBox(height: 8),
          Text(
            'Halaman ${book.halamanTerakhir} dari ${book.totalHalaman}',
            style: AppText.body,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab({
    required IconData icon,
    required String judul,
    required String deskripsi,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(judul, style: AppText.bodyStrong, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(deskripsi, style: AppText.body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}