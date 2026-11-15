import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Ilustrasi rak buku dari Container (bukan gambar).
class BookshelfIllustration extends StatelessWidget {
  const BookshelfIllustration({super.key});

  // Ukuran punggung buku (lebar, tinggi), urut dari kiri
  static const _ukuran = <List<double>>[
    [16, 89],
    [21, 73],
    [14, 98],
    [23, 80],
    [18, 66],
    [15, 94],
    [26, 85],
    [17, 76],
    [19, 101],
  ];
  static const _jarak = 3.2;
  static const _tinggiPapan = 5.0;
  static const _lebarRak = 229.0;

  /// Satu punggung buku dengan satu garis pita di dekat atas.
  Widget _buku(double lebar, double tinggi, Color warna, Color pita) {
    return Container(
      width: lebar,
      height: tinggi,
      decoration: BoxDecoration(
        color: warna,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 13),
          child: Container(height: 3.5, color: pita),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buku = <Widget>[];
    for (var i = 0; i < _ukuran.length; i++) {
      buku.add(
        _buku(
          _ukuran[i][0],
          _ukuran[i][1],
          AppColors.shelfBooks[i][0],
          AppColors.shelfBooks[i][1],
        ),
      );
      if (i < _ukuran.length - 1) buku.add(const SizedBox(width: _jarak));
    }

    return SizedBox(
      width: _lebarRak,
      height: 101 + _tinggiPapan,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Deretan buku berdiri
          Positioned(
            left: 0,
            bottom: _tinggiPapan,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: buku,
            ),
          ),
          // Buku hijau yang miring bersandar (~15 derajat)
          Positioned(
            left: 192,
            bottom: _tinggiPapan,
            child: Transform.rotate(
              angle: 15 * math.pi / 180,
              alignment: Alignment.bottomLeft,
              child: Container(
                width: 20,
                height: 86,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ),
            ),
          ),
          // Papan rak berujung bulat
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: _tinggiPapan,
              decoration: BoxDecoration(
                color: AppColors.shelf,
                borderRadius: BorderRadius.circular(_tinggiPapan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
