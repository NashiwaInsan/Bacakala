import 'package:material_ui/material_ui.dart';

import '../../models/reading_stats.dart';
import '../../services/stats_service.dart';
import '../../utils/date_label.dart';
import '../../widgets/bottom_nav_bar.dart';

/// Halaman Statistik (Bab 2.2.7), dibuka dari menu Statistik
/// di bottom navigation (route '/statistik').
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, this.onStartSession});

  /// Aksi tombol "Mulai sesi membaca" saat belum ada data,
  /// misalnya pindah ke tab Rak Buku.
  final VoidCallback? onStartSession;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _statsService = StatsService();

  StatsPeriod _period = StatsPeriod.minggu;
  late Future<ReadingStats> _future;

  @override
  void initState() {
    super.initState();
    _future = _statsService.getStats(_period);
  }

  Future<void> _reload() async {
    final future = _statsService.getStats(_period);
    setState(() => _future = future);
    await future;
  }

  void _changePeriod(StatsPeriod period) {
    _period = period;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: BottomNavBar.statistikIndex),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Statistik', style: theme.textTheme.headlineMedium),
                  ),
                  SegmentedButton<StatsPeriod>(
                    segments: [
                      for (final p in StatsPeriod.values)
                        ButtonSegment(value: p, label: Text(p.label)),
                    ],
                    selected: {_period},
                    showSelectedIcon: false,
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    onSelectionChanged: (s) => _changePeriod(s.first),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FutureBuilder<ReadingStats>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return _ErrorView(onRetry: _reload);
                  }
                  final stats = snapshot.data!;
                  if (stats.isEmpty) {
                    return _EmptyView(onStartSession: widget.onStartSession);
                  }
                  return _StatsContent(stats: stats);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.stats});

  final ReadingStats stats;

  String get _comparison {
    final diff = stats.difference;
    final previous = stats.period.previousLabel;
    if (diff > 0) return '$diff menit lebih banyak dari $previous';
    if (diff < 0) return '${-diff} menit lebih sedikit dari $previous';
    return 'Sama dengan $previous';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final diff = stats.difference;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${stats.totalMinutes}',
              style: theme.textTheme.displayMedium?.copyWith(color: colors.primary),
            ),
            const SizedBox(width: 8),
            Text('menit membaca', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              diff >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: diff >= 0 ? colors.primary : colors.error,
            ),
            const SizedBox(width: 4),
            Text(
              _comparison,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: diff >= 0 ? colors.primary : colors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _BarChart(bars: stats.bars, average: stats.averageMinutes),
        const SizedBox(height: 16),
        Row(
          children: [
            _NumberCard(value: stats.totalPages, label: 'halaman\ndibaca'),
            const SizedBox(width: 10),
            _NumberCard(value: stats.booksFinished, label: 'buku\nselesai'),
            const SizedBox(width: 10),
            _NumberCard(value: stats.averageSessionMinutes, label: 'menit\nper sesi'),
          ],
        ),
        if (stats.favoriteHourStart != null) ...[
          const SizedBox(height: 16),
          _FavoriteHour(startHour: stats.favoriteHourStart!),
        ],
      ],
    );
  }
}

/// Grafik batang dengan garis putus-putus rata-rata.
class _BarChart extends StatelessWidget {
  const _BarChart({required this.bars, required this.average});

  final List<StatsBar> bars;
  final int average;

  static const double _chartHeight = 150;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final maxMinutes = bars.fold<int>(1, (m, b) => b.minutes > m ? b.minutes : m);
    double heightOf(int minutes) => _chartHeight * minutes / maxMinutes;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          SizedBox(
            height: _chartHeight + 20,
            child: Stack(
              children: [
                if (average > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: heightOf(average),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('rata-rata $average', style: theme.textTheme.labelSmall),
                        CustomPaint(
                          size: const Size(double.infinity, 1),
                          painter: _DashedLinePainter(colors.outline),
                        ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final bar in bars)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (bar.minutes > 0)
                              Text(
                                '${bar.minutes}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: bar.isCurrent ? FontWeight.bold : null,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              height: bar.minutes > 0 ? heightOf(bar.minutes) : 3,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: bar.minutes == 0
                                    ? colors.outlineVariant
                                    : bar.isCurrent
                                        ? colors.primary
                                        : colors.primary.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final bar in bars)
                Expanded(
                  child: Text(
                    bar.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: bar.isCurrent ? FontWeight.bold : null,
                      color: bar.isCurrent ? colors.onSurface : colors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 4.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => oldDelegate.color != color;
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_thousands(value), style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  /// 1284 → 1.284
  static String _thousands(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
}

class _FavoriteHour extends StatelessWidget {
  const _FavoriteHour({required this.startHour});

  final int startHour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final range = '${DateLabel.hour(startHour)}–${DateLabel.hour((startHour + 2) % 24)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Jam favoritmu membaca: $range', style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({this.onStartSession});

  final VoidCallback? onStartSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 72, color: theme.colorScheme.primaryContainer),
          const SizedBox(height: 12),
          Text('Belum ada sesi membaca', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Statistik muncul setelah kamu menyimpan sesi pertama. '
            'Mulai dari buku yang sedang kamu baca.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (onStartSession != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onStartSession,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Mulai sesi membaca'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          const Text('Statistik gagal dimuat. Cek koneksi internet.'),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
