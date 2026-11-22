/// Format tanggal dan waktu berbahasa Indonesia tanpa package tambahan.
class DateLabel {
  DateLabel._();

  static const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  static const _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const shortDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  /// 13 Nov
  static String dayMonth(DateTime date) =>
      '${date.day} ${shortMonths[date.month - 1]}';

  /// Sabtu, 19 Desember 2026
  static String full(DateTime date) =>
      '${_days[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]} ${date.year}';

  /// 2026-12-19, format kolom `date` di PostgreSQL.
  static String isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// baru saja / 40 menit lalu / 2 jam lalu / 13 Nov
  static String relative(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return dayMonth(time);
  }

  /// 19.00
  static String hour(int hour) => '${hour.toString().padLeft(2, '0')}.00';

  /// Tanggal tanpa jam, untuk menghitung selisih hari.
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
