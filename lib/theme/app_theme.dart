import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semua warna aplikasi. Jangan tulis warna langsung di screen/widget.
class AppColors {
  AppColors._();

  static const background = Color(0xFFF8F7F4);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE6E4DE);

  static const primary = Color(0xFF2D6A4F);
  static const primarySoft = Color(0xFFD2E7DD); // track progress, pil navbar

  static const yellowSoft = Color(0xFFFBEDC9); // kartu Beruntun
  static const brown = Color(0xFFC0872D);
  static const brownDark = Color(0xFF5A3E1D); // angka di kartu Beruntun

  static const textPrimary = Color(0xFF1F2622);
  static const textSecondary = Color(0xFF5D625D);
  static const textHint = Color(0xFF9A9D99);

  static const white = Color(0xFFFFFFFF);
  static const shelf = Color(0xFF1F2622); // papan rak
  static const coverDefault = Color(0xFF1F4E5F); // sampul placeholder
  static const coverText = Color(0xFFF1EDE3); // teks krem di sampul

  static const danger = Color(0xFFB5532C); // tombol Keluar

  /// Pasangan (warna buku, warna pita) untuk ilustrasi rak di halaman login.
  static const shelfBooks = <List<Color>>[
    [Color(0xFF1F4E5F), Color(0xFFB3BBB0)],
    [Color(0xFF7A8B4F), Color(0xFFD1D3B5)],
    [Color(0xFFB5532C), Color(0xFFE4B898)],
    [Color(0xFFE9D8A6), Color(0xFF6F6247)],
    [Color(0xFF5B2A3C), Color(0xFFC4A39F)],
    [Color(0xFF2F3A33), Color(0xFFA5B29B)],
    [Color(0xFFF1EDE3), Color(0xFF68927C)],
    [Color(0xFF355C7D), Color(0xFFBBC3C6)],
    [Color(0xFFC98B3A), Color(0xFF5A3E1D)],
  ];

  /// Warna punggung buku yang sudah selesai di kartu Target (bergantian).
  static const finishedSpines = <Color>[
    Color(0xFFB5532C),
    Color(0xFFE9D8A6),
    Color(0xFF5B2A3C),
    Color(0xFF2F3A33),
  ];
}

/// Semua gaya teks. Serif = Literata semibold, lainnya = Figtree.
class AppText {
  AppText._();

  static TextStyle _serif(double size, Color color, {double height = 1.2}) =>
      GoogleFonts.literata(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        height: height,
      );

  static TextStyle _sans(
    double size,
    Color color, {
    FontWeight weight = FontWeight.w400,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.figtree(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  // --- Serif ---
  static TextStyle get logo => _serif(24, AppColors.primary, height: 1.2);
  static TextStyle get logoSplash => _serif(40, AppColors.primary);
  static TextStyle get display =>
      _serif(29, AppColors.textPrimary, height: 1.35);
  static TextStyle get homeTitle =>
      _serif(27, AppColors.textPrimary, height: 1.22);
  static TextStyle get bookTitle =>
      _serif(19, AppColors.textPrimary, height: 1.35);
  static TextStyle get bigNumberGreen =>
      _serif(34, AppColors.primary, height: 1);
  static TextStyle get bigNumber =>
      _serif(28, AppColors.textPrimary, height: 1);
  static TextStyle get bigNumberBrown =>
      _serif(28, AppColors.brownDark, height: 1);
  static TextStyle get coverTitle =>
      _serif(14, AppColors.coverText, height: 1.1);

  // --- Figtree ---
  static TextStyle get subtitle =>
      _sans(15.2, AppColors.textSecondary, height: 1.3);
  static TextStyle get label =>
      _sans(14, AppColors.textSecondary, weight: FontWeight.w600);
  static TextStyle get input => _sans(16, AppColors.textPrimary);
  static TextStyle get button =>
      _sans(17, AppColors.white, weight: FontWeight.w600);
  static TextStyle get link =>
      _sans(14.5, AppColors.primary, weight: FontWeight.w600);
  static TextStyle get body => _sans(15, AppColors.textSecondary);
  static TextStyle get bodyStrong =>
      _sans(15, AppColors.textPrimary, weight: FontWeight.w600);
  static TextStyle get caption => _sans(13.5, AppColors.textSecondary);
  static TextStyle get hint => _sans(13, AppColors.textHint, height: 1.5);
  static TextStyle get hintStrong =>
      _sans(13.5, AppColors.textHint, weight: FontWeight.w600);
  static TextStyle get overline => _sans(
    11.5,
    AppColors.primary,
    weight: FontWeight.w700,
    letterSpacing: 1.6,
  );
  static TextStyle get percent =>
      _sans(14, AppColors.primary, weight: FontWeight.w700);
  static TextStyle get brownLabel =>
      _sans(14.5, AppColors.brown, weight: FontWeight.w600);
  static TextStyle get brownUnit => _sans(15, AppColors.brownDark);
  static TextStyle get coverAuthor => _sans(
    6,
    AppColors.coverText,
    weight: FontWeight.w600,
    letterSpacing: 0.3,
  );
  static TextStyle get greeting => _sans(14.5, AppColors.textSecondary);
  static TextStyle get avatar =>
      _sans(18, AppColors.white, weight: FontWeight.w700);
  static TextStyle get dayLabel => _sans(13, AppColors.textHint);
  static TextStyle get dayLabelToday =>
      _sans(13, AppColors.textPrimary, weight: FontWeight.w800);
  static TextStyle get navActive =>
      _sans(12.5, AppColors.primary, weight: FontWeight.w700);
  static TextStyle get navInactive =>
      _sans(12.5, AppColors.textSecondary, weight: FontWeight.w500);
}

/// Ukuran umum yang dipakai berulang.
class AppSizes {
  AppSizes._();

  static const screenPadding = 24.0;
  static const authPadding =
      28.0; // halaman login/register di desain sedikit lebih lebar
  static const buttonHeight = 56.0;
  static const inputHeight = 60.0;
  static const radiusField = 18.0;
  static const radiusCard = 24.0;
}

class AppTheme {
  AppTheme._();

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSizes.radiusField),
    borderSide: BorderSide(color: color, width: 1.5),
  );

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
      ),
      textTheme: GoogleFonts.figtreeTextTheme(),
      // Input putih, tanpa ikon, border hijau saat fokus
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 22,
        ),
        hintStyle: GoogleFonts.figtree(color: AppColors.textHint, fontSize: 16),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primary),
      ),
      // Tombol utama: penuh lebar, tinggi 56, radius 18
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusField),
          ),
          textStyle: AppText.button,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.figtree(
          color: AppColors.white,
          fontSize: 14,
        ),
      ),
    );
  }
}
