import 'package:material_ui/material_ui.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';

/// Sampul buku rasio 2:3 dengan efek punggung (strip gelap di kiri) dan
/// bayangan halus. Jika [Book.coverUrl] kosong, gagal, atau masih dimuat,
/// yang tampil adalah sampul otomatis yang digambar dari judul.
class BookCover extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;

  const BookCover({super.key, required this.book, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(5);

    return AspectRatio(
      aspectRatio: 2 / 3,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: const [
              BoxShadow(
                color: AppColors.coverShadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final otomatis = AutoCover(
                  judul: book.judul,
                  penulis: book.penulis,
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (book.coverUrl == null)
                      otomatis
                    else
                      Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progres) =>
                            progres == null ? child : otomatis,
                        errorBuilder: (_, _, _) => otomatis,
                      ),
                    // Punggung buku
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: w * 0.05,
                      child: const ColoredBox(color: AppColors.coverSpine),
                    ),
                    Positioned(
                      left: w * 0.05,
                      top: 0,
                      bottom: 0,
                      width: 1,
                      child: const ColoredBox(color: AppColors.coverSpineLight),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Sampul polos dari judul: warna dan bentuk dekoratif dipilih dari hash judul
/// supaya buku yang sama selalu tampil sama. Ukuran teks mengikuti lebar.
class AutoCover extends StatelessWidget {
  final String judul;
  final String penulis;

  const AutoCover({super.key, required this.judul, required this.penulis});

  /// Hash sederhana yang stabil di semua platform (bukan String.hashCode).
  static int _hash(String s) {
    var h = 0;
    for (final c in s.trim().toLowerCase().codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final hash = _hash(judul);
    final palet = AppColors.shelfBooks;
    final latar = palet[hash % palet.length][0];
    final aksen = palet[hash % palet.length][1];
    final bentuk = (hash ~/ palet.length) % 4;

    // Latar terang -> teks pakai warna aksen yang gelap; latar gelap -> krem.
    final terang = latar.computeLuminance() > 0.45;
    final warnaTeks = terang ? aksen : AppColors.coverText;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final kiri = w * 0.11;

        return ColoredBox(
          color: latar,
          child: Stack(
            children: [
              _dekorasi(bentuk, w, h, aksen),
              Positioned(
                left: kiri,
                right: w * 0.09,
                top: h * 0.08,
                child: Text(
                  judul,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.coverTitle.copyWith(
                    fontSize: w * 0.135,
                    height: 1.08,
                    color: warnaTeks,
                  ),
                ),
              ),
              Positioned(
                left: kiri,
                right: w * 0.06,
                bottom: h * 0.06,
                child: Text(
                  penulis.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.coverAuthor.copyWith(
                    fontSize: w * 0.06,
                    letterSpacing: w * 0.005,
                    color: warnaTeks.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Satu bentuk sederhana: lingkaran, pita, lengkung, atau garis.
  Widget _dekorasi(int bentuk, double w, double h, Color aksen) {
    switch (bentuk) {
      case 0: // lingkaran
        final d = w * 0.5;
        return Positioned(
          right: w * 0.08,
          bottom: h * 0.2,
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(color: aksen, shape: BoxShape.circle),
          ),
        );
      case 1: // pita mendatar
        return Positioned(
          left: 0,
          right: 0,
          top: h * 0.58,
          height: h * 0.18,
          child: ColoredBox(color: aksen),
        );
      case 2: // lengkung (pintu)
        final lebar = w * 0.55;
        return Positioned(
          left: (w - lebar) / 2,
          bottom: h * 0.12,
          child: Container(
            width: lebar,
            height: h * 0.42,
            decoration: BoxDecoration(
              color: aksen.withValues(alpha: 0.35),
              border: Border.all(color: aksen, width: w * 0.012),
              borderRadius: BorderRadius.vertical(top: Radius.circular(lebar)),
            ),
          ),
        );
      default: // garis-garis
        return Positioned(
          left: w * 0.11,
          right: w * 0.11,
          top: h * 0.55,
          child: Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                Container(height: 1.2, color: aksen.withValues(alpha: 0.8)),
                if (i < 3) SizedBox(height: h * 0.055),
              ],
            ],
          ),
        );
    }
  }
}
