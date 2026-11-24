import 'package:material_ui/material_ui.dart';

import '../../models/club.dart';
import '../../services/club_service.dart';
import '../../utils/date_label.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'club_detail_screen.dart';
import 'club_form_screen.dart';

/// Halaman Daftar Klub (Bab 2.2.8 poin 1), dibuka dari menu Klub
/// di bottom navigation (route '/klub').
class ClubListScreen extends StatefulWidget {
  const ClubListScreen({super.key});

  @override
  State<ClubListScreen> createState() => _ClubListScreenState();
}

class _ClubListScreenState extends State<ClubListScreen> {
  final _clubService = ClubService();
  final _kodeController = TextEditingController();

  late Future<List<Club>> _future;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _future = _clubService.getMyClubs();
  }

  @override
  void dispose() {
    _kodeController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final future = _clubService.getMyClubs();
    setState(() => _future = future);
    await future;
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _join() async {
    final kode = _kodeController.text.trim();
    if (kode.isEmpty) {
      _showMessage('Masukkan kode undangan dulu.');
      return;
    }
    setState(() => _isJoining = true);
    try {
      final club = await _clubService.joinClub(kode);
      _kodeController.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      await _openDetail(club);
    } on ClubNotFoundException {
      if (mounted) _showMessage('Kode $kode tidak ditemukan. Cek lagi ke temanmu.');
    } catch (_) {
      if (mounted) _showMessage('Gagal bergabung. Cek koneksi lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _openDetail(Club club) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClubDetailScreen(club: club)),
    );
    _reload();
  }

  /// Daftar selalu dimuat ulang setelah kembali dari form, termasuk saat
  /// pengguna menekan Buka klub (form diganti oleh Detail Klub).
  Future<void> _openForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClubFormScreen()),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      bottomNavigationBar: const BottomNavBar(currentIndex: BottomNavBar.klubIndex),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Buat klub'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              Text('Klub Baca', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 20),
              _JoinCard(
                controller: _kodeController,
                isLoading: _isJoining,
                onJoin: _join,
              ),
              const SizedBox(height: 24),
              Text(
                'KLUB YANG KAMU IKUTI',
                style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Club>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        const Text('Daftar klub gagal dimuat.'),
                        TextButton(onPressed: _reload, child: const Text('Coba lagi')),
                      ],
                    );
                  }
                  final clubs = snapshot.data!;
                  if (clubs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Kamu belum ikut klub. Masukkan kode undangan dari '
                        'teman atau buat klub sendiri.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final club in clubs) ...[
                        _ClubCard(club: club, onTap: () => _openDetail(club)),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({
    required this.controller,
    required this.isLoading,
    required this.onJoin,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Punya kode undangan?',
            style: theme.textTheme.titleSmall?.copyWith(color: colors.onPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(color: colors.onPrimary, letterSpacing: 1.5),
                  cursorColor: colors.onPrimary,
                  onSubmitted: (_) => onJoin(),
                  decoration: InputDecoration(
                    hintText: 'KSM-4821',
                    hintStyle: TextStyle(color: colors.onPrimary.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: colors.onPrimary.withValues(alpha: 0.12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: isLoading ? null : onJoin,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.surface,
                    foregroundColor: colors.primary,
                    // Lebar eksplisit: tombol di dalam Row tidak boleh ikut
                    // lebar tak terbatas dari tema.
                    minimumSize: const Size(88, 48),
                  ),
                  child: isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gabung'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club, required this.onTap});

  final Club club;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sisa = club.sisaHari();
    final targetText = club.isSelesai
        ? 'Selesai · ${DateLabel.dayMonth(club.targetSelesai)}'
        : 'Target ${DateLabel.dayMonth(club.targetSelesai)} · '
            '${sisa == 0 ? 'hari ini' : '$sisa hari lagi'}';

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BookSpine(title: club.judulBuku),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(club.nama, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Membaca ${club.judulBuku}',
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.group_outlined, size: 16, color: colors.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              '${club.jumlahAnggota ?? 1} anggota',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.flag_outlined, size: 16, color: colors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(child: Text(targetText, style: theme.textTheme.bodySmall)),
                  Text(
                    'Kamu ${club.progresSaya ?? 0}%',
                    style: theme.textTheme.labelMedium?.copyWith(color: colors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sampul sederhana berisi judul buku (tabel clubs belum menyimpan sampul).
class _BookSpine extends StatelessWidget {
  const _BookSpine({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 52,
      height: 76,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.tertiary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        title,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.onTertiary, fontSize: 8, height: 1.2),
      ),
    );
  }
}