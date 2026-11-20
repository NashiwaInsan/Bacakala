import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reading_stats.dart';
import '../utils/date_label.dart';

/// Menghitung statistik dari tabel `reading_sessions` (Bab 2.2.7).
///
/// Data diambil sekali untuk periode berjalan dan periode sebelumnya,
/// lalu dihitung di aplikasi. RLS memastikan hanya sesi milik pengguna
/// yang ikut terambil.
class StatsService {
  StatsService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<ReadingStats> getStats(StatsPeriod period, {DateTime? now}) async {
    final today = DateLabel.dateOnly(now ?? DateTime.now());
    final range = _PeriodRange.of(period, today);

    final rows = await _client
        .from('reading_sessions')
        .select('book_id, waktu_mulai, durasi_menit, halaman_awal, halaman_akhir, '
            'books(total_halaman)')
        .gte('waktu_mulai', range.previousStart.toUtc().toIso8601String())
        .lt('waktu_mulai', range.end.toUtc().toIso8601String());

    final all = rows.map(_Session.fromJson).toList();
    final current = all.where((s) => !s.start.isBefore(range.start)).toList();
    final previous = all.where((s) => s.start.isBefore(range.start));

    return _calculate(period, range, today, current, previous);
  }

  ReadingStats _calculate(
    StatsPeriod period,
    _PeriodRange range,
    DateTime today,
    List<_Session> current,
    Iterable<_Session> previous,
  ) {
    final totalMinutes = _sumMinutes(current);
    final bars = _buildBars(period, range, today, current);

    final elapsedBars = bars.indexWhere((b) => b.isCurrent) + 1;
    final averageMinutes = elapsedBars == 0
        ? 0
        : (bars.take(elapsedBars).fold<int>(0, (sum, b) => sum + b.minutes) / elapsedBars)
            .round();

    final finishedBooks = current
        .where((s) => s.totalPages != null && s.endPage >= s.totalPages!)
        .map((s) => s.bookId)
        .toSet();

    return ReadingStats(
      period: period,
      totalMinutes: totalMinutes,
      previousMinutes: _sumMinutes(previous),
      bars: bars,
      averageMinutes: averageMinutes,
      totalPages: current.fold(0, (sum, s) => sum + s.pagesRead),
      booksFinished: finishedBooks.length,
      averageSessionMinutes:
          current.isEmpty ? 0 : (totalMinutes / current.length).round(),
      sessionCount: current.length,
      favoriteHourStart: _favoriteHour(current),
    );
  }

  int _sumMinutes(Iterable<_Session> sessions) =>
      sessions.fold(0, (sum, s) => sum + s.minutes);

  List<StatsBar> _buildBars(
    StatsPeriod period,
    _PeriodRange range,
    DateTime today,
    List<_Session> sessions,
  ) {
    switch (period) {
      case StatsPeriod.minggu:
        return List.generate(7, (i) {
          final day = range.start.add(Duration(days: i));
          return StatsBar(
            label: DateLabel.shortDays[i],
            minutes: _sumMinutes(sessions.where((s) => DateLabel.dateOnly(s.start) == day)),
            isCurrent: day == today,
          );
        });
      case StatsPeriod.bulan:
        // Dibagi per 7 hari: tgl 1–7, 8–14, 15–21, 22–28, 29–akhir.
        final daysInMonth = range.end.subtract(const Duration(days: 1)).day;
        final weekCount = (daysInMonth / 7).ceil();
        return List.generate(weekCount, (i) {
          bool inWeek(int day) => (day - 1) ~/ 7 == i;
          return StatsBar(
            label: 'Mg ${i + 1}',
            minutes: _sumMinutes(sessions.where((s) => inWeek(s.start.day))),
            isCurrent: inWeek(today.day),
          );
        });
      case StatsPeriod.tahun:
        return List.generate(12, (i) {
          return StatsBar(
            label: DateLabel.shortMonths[i],
            minutes: _sumMinutes(sessions.where((s) => s.start.month == i + 1)),
            isCurrent: today.month == i + 1,
          );
        });
    }
  }

  /// Mencari rentang 2 jam dengan sesi terbanyak, berdasarkan jam mulai sesi.
  int? _favoriteHour(List<_Session> sessions) {
    if (sessions.isEmpty) return null;
    final perHour = List.filled(24, 0);
    for (final s in sessions) {
      perHour[s.start.hour]++;
    }
    var bestHour = 0;
    var bestCount = -1;
    for (var h = 0; h < 24; h++) {
      final count = perHour[h] + perHour[(h + 1) % 24];
      if (count > bestCount) {
        bestHour = h;
        bestCount = count;
      }
    }
    return bestHour;
  }
}

class _PeriodRange {
  const _PeriodRange(this.previousStart, this.start, this.end);

  final DateTime previousStart;
  final DateTime start;

  /// Batas akhir (tidak termasuk).
  final DateTime end;

  factory _PeriodRange.of(StatsPeriod period, DateTime today) {
    switch (period) {
      case StatsPeriod.minggu:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        return _PeriodRange(
          monday.subtract(const Duration(days: 7)),
          monday,
          monday.add(const Duration(days: 7)),
        );
      case StatsPeriod.bulan:
        return _PeriodRange(
          DateTime(today.year, today.month - 1, 1),
          DateTime(today.year, today.month, 1),
          DateTime(today.year, today.month + 1, 1),
        );
      case StatsPeriod.tahun:
        return _PeriodRange(
          DateTime(today.year - 1, 1, 1),
          DateTime(today.year, 1, 1),
          DateTime(today.year + 1, 1, 1),
        );
    }
  }
}

class _Session {
  const _Session({
    required this.bookId,
    required this.start,
    required this.minutes,
    required this.pagesRead,
    required this.endPage,
    this.totalPages,
  });

  final String bookId;
  final DateTime start;
  final int minutes;
  final int pagesRead;
  final int endPage;
  final int? totalPages;

  factory _Session.fromJson(Map<String, dynamic> json) {
    final startPage = json['halaman_awal'] as int;
    final endPage = json['halaman_akhir'] as int;
    final book = json['books'] as Map<String, dynamic>?;
    return _Session(
      bookId: json['book_id'].toString(),
      start: DateTime.parse(json['waktu_mulai'] as String).toLocal(),
      minutes: json['durasi_menit'] as int,
      pagesRead: endPage > startPage ? endPage - startPage : 0,
      endPage: endPage,
      totalPages: book?['total_halaman'] as int?,
    );
  }
}
