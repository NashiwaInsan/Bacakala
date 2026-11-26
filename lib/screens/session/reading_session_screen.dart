import 'dart:async';
import 'package:material_ui/material_ui.dart';

import 'package:bacakala/models/book.dart';
import 'package:bacakala/screens/notes/note_form_screen.dart';
import 'package:bacakala/services/auth_service.dart';
import 'package:bacakala/services/reading_session_service.dart';
import 'package:bacakala/theme/app_theme.dart';

class ReadingSessionScreen extends StatefulWidget {
  final Book book;

  const ReadingSessionScreen({super.key, required this.book});

  @override
  State<ReadingSessionScreen> createState() => _ReadingSessionScreenState();
}

class _ReadingSessionScreenState extends State<ReadingSessionScreen> {
  final _sessionService = ReadingSessionService();

  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = true;
  bool _dimMode = false;

  static const _bgGreen = Color(0xFF1A4331);
  static const _bgDim = Color(0xFF0F261C);
  static const _cream = Color(0xFFF3ECE1);
  static const _amber = Color(0xFFE5A93B);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isRunning && mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _togglePause() {
    setState(() => _isRunning = !_isRunning);
  }

  String get _formattedTime {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get _durasiMenit => (_elapsedSeconds / 60).ceil().clamp(1, 9999);

  Future<void> _bukaKutipan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteFormScreen(
          bookId: widget.book.id,
          bookTitle: widget.book.judul,
          lastPage: widget.book.halamanTerakhir,
          totalPages: widget.book.totalHalaman,
        ),
      ),
    );
  }

  Future<void> _akhiriSesi() async {
    setState(() => _isRunning = false);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaveSessionSheet(
        book: widget.book,
        durasiMenit: _durasiMenit,
        onSave: (halamanAkhir) async {
          await _sessionService.createSession(
            bookId: widget.book.id,
            halamanAwal: widget.book.halamanTerakhir,
            halamanAkhir: halamanAkhir,
            durasiMenit: _durasiMenit,
          );
        },
      ),
    );

    if (!mounted) return;
    if (saved == true) {
      // Kembali ke Detail Buku dengan sinyal berhasil simpan
      Navigator.pop(context, true);
    } else if (saved == false) {
      // Buang sesi
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Scaffold(
      backgroundColor: _dimMode ? _bgDim : _bgGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Text(
                    'Sesi membaca',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _dimMode = !_dimMode),
                    icon: Icon(
                      _dimMode
                          ? Icons.nightlight_round
                          : Icons.nightlight_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Kartu Info Buku
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 62,
                        color: AppColors.primarySoft,
                        child: book.coverUrl != null
                            ? Image.network(
                                book.coverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.book_outlined,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.book_outlined,
                                color: AppColors.primary,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.judul,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'mulai dari halaman ${book.halamanTerakhir}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Timer Besar
              Text(
                _formattedTime,
                style: const TextStyle(
                  color: _cream,
                  fontSize: 72,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'menit  ·  detik',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // Bar Visualisasi Sesi
              _buildVisualizer(),
              const SizedBox(height: 10),
              Text(
                _isRunning ? 'Sesi sedang berjalan' : 'Sesi dijeda',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),

              const Spacer(),

              // Tombol Kontrol Bawah (Akhiri, Jeda/Lanjut, Kutipan)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleAction(
                    icon: Icons.stop_rounded,
                    label: 'Akhiri',
                    onTap: _akhiriSesi,
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _togglePause,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            color: _cream,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isRunning
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: _bgGreen,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isRunning ? 'Jeda' : 'Lanjut',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  _buildCircleAction(
                    icon: Icons.edit_outlined,
                    label: 'Kutipan',
                    onTap: _bukaKutipan,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Text(
                'Layar boleh dimatikan, timer tetap berjalan.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualizer() {
    const totalBars = 36;
    // Isi bar bertambah tiap 10 detik (penuh dalam 6 menit untuk efek visual)
    final activeBars = ((_elapsedSeconds / 10).floor()).clamp(1, totalBars);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(totalBars, (i) {
        final isTall = i % 5 == 0;
        final isActive = i < activeBars;
        return Container(
          width: 3,
          height: isTall ? 18 : 10,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? _amber : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// Bottom Sheet "Sesi selesai" sesuai desain Figma
class _SaveSessionSheet extends StatefulWidget {
  final Book book;
  final int durasiMenit;
  final Future<void> Function(int halamanAkhir) onSave;

  const _SaveSessionSheet({
    required this.book,
    required this.durasiMenit,
    required this.onSave,
  });

  @override
  State<_SaveSessionSheet> createState() => _SaveSessionSheetState();
}

class _SaveSessionSheetState extends State<_SaveSessionSheet> {
  late int _halamanAkhir;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _halamanAkhir = widget.book.halamanTerakhir;
  }

  int get _selisih => _halamanAkhir - widget.book.halamanTerakhir;

  int get _persenBaru {
    if (widget.book.totalHalaman <= 0) return 0;
    return ((_halamanAkhir / widget.book.totalHalaman).clamp(0.0, 1.0) * 100)
        .round();
  }

  Future<void> _simpan() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_halamanAkhir);
      if (mounted) Navigator.pop(context, true);
    } on ServiceException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal menyimpan sesi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sesi selesai',
            style: AppText.bodyStrong.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.durasiMenit} menit bersama ${book.judul}.',
            style: AppText.body,
          ),
          const SizedBox(height: 20),
          Text('Sampai halaman berapa?', style: AppText.bodyStrong),
          const SizedBox(height: 12),

          // Stepper Halaman
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F5F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _halamanAkhir > book.halamanTerakhir
                      ? () => setState(() => _halamanAkhir--)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  icon: const Icon(Icons.remove),
                ),
                Column(
                  children: [
                    Text(
                      '$_halamanAkhir',
                      style: AppText.bodyStrong.copyWith(fontSize: 28),
                    ),
                    Text(
                      'dari ${book.totalHalaman}',
                      style: AppText.hintStrong,
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _halamanAkhir < book.totalHalaman
                      ? () => setState(() => _halamanAkhir++)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Info Kenaikan Progres
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '+$_selisih halaman. Progres naik dari ${book.persen}% ke $_persenBaru%.',
                    style: AppText.bodyStrong.copyWith(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kalau sampai halaman ${book.totalHalaman}, status buku otomatis jadi Selesai.',
                  style: AppText.hintStrong,
                ),
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Simpan sesi'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context, false),
              child: Text('Buang sesi ini', style: AppText.bodyStrong),
            ),
          ),
        ],
      ),
    );
  }
}