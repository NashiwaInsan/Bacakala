/// Periode yang bisa dipilih di halaman Statistik.
enum StatsPeriod {
  minggu('Minggu', 'minggu lalu'),
  bulan('Bulan', 'bulan lalu'),
  tahun('Tahun', 'tahun lalu');

  const StatsPeriod(this.label, this.previousLabel);

  final String label;

  /// Dipakai di kalimat perbandingan, misalnya "dari minggu lalu".
  final String previousLabel;
}

/// Satu batang di grafik: hari (Minggu), pekan (Bulan), atau bulan (Tahun).
class StatsBar {
  const StatsBar({
    required this.label,
    required this.minutes,
    required this.isCurrent,
  });

  final String label;
  final int minutes;

  /// Batang hari/pekan/bulan ini, ditampilkan lebih gelap.
  final bool isCurrent;
}

/// Rekap membaca untuk satu periode (Bab 2.2.7).
class ReadingStats {
  const ReadingStats({
    required this.period,
    required this.totalMinutes,
    required this.previousMinutes,
    required this.bars,
    required this.averageMinutes,
    required this.totalPages,
    required this.booksFinished,
    required this.averageSessionMinutes,
    required this.sessionCount,
    this.favoriteHourStart,
  });

  final StatsPeriod period;
  final int totalMinutes;

  /// Total menit pada periode sebelumnya, untuk perbandingan.
  final int previousMinutes;
  final List<StatsBar> bars;

  /// Rata-rata menit per batang sampai batang saat ini (garis putus-putus).
  final int averageMinutes;
  final int totalPages;
  final int booksFinished;
  final int averageSessionMinutes;
  final int sessionCount;

  /// Jam mulai rentang 2 jam yang paling sering dipakai membaca,
  /// misalnya 19 untuk 19.00–21.00. `null` jika belum ada sesi.
  final int? favoriteHourStart;

  bool get isEmpty => sessionCount == 0;

  int get difference => totalMinutes - previousMinutes;
}
