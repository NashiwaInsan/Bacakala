import 'package:material_ui/material_ui.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';
import 'progress_bar.dart';

/// Kartu "Sedang Dibaca". Jika [book] null, tampil empty state.
class BookCard extends StatelessWidget {
  final Book? book;
  final VoidCallback onContinue;

  const BookCard({super.key, required this.book, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: book == null ? _buildEmpty() : _buildBook(book!),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 40,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text('Belum ada buku yang sedang dibaca', style: AppText.bodyStrong),
          const SizedBox(height: 4),
          Text(
            'Tambahkan buku ke rakmu untuk mulai melacak progres.',
            textAlign: TextAlign.center,
            style: AppText.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildBook(Book b) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Cover(book: b),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                // Samakan tinggi dengan sampul agar progres rata bawah
                height: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SEDANG DIBACA', style: AppText.overline),
                    const SizedBox(height: 4),
                    Text(
                      b.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bookTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.penulis,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body,
                    ),
                    const Spacer(),
                    ProgressBar(value: b.progres),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'hal ${b.halamanTerakhir} / ${b.totalHalaman}',
                          style: AppText.caption,
                        ),
                        Text('${b.persen}%', style: AppText.percent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: const Text('Lanjutkan baca'),
          ),
        ),
      ],
    );
  }
}

/// Sampul buku: gambar dari cover_url, atau placeholder bila kosong/gagal.
class _Cover extends StatelessWidget {
  final Book book;
  const _Cover({required this.book});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(8);

    return Container(
      width: 87,
      height: 130,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: book.coverUrl == null
            ? _placeholder()
            : Image.network(
                book.coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.coverDefault,
      padding: const EdgeInsets.fromLTRB(8, 10, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            book.judul,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppText.coverTitle,
          ),
          const Spacer(),
          // Tiga garis tipis
          for (var i = 0; i < 3; i++) ...[
            Container(
              height: 1,
              color: AppColors.coverText.withValues(alpha: 0.35),
            ),
            if (i < 2) const SizedBox(height: 4),
          ],
          const SizedBox(height: 10),
          Text(
            book.penulis.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.coverAuthor,
          ),
        ],
      ),
    );
  }
}
