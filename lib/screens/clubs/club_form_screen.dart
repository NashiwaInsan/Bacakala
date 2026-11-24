import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../models/club.dart';
import '../../services/club_service.dart';
import '../../utils/date_label.dart';
import 'club_detail_screen.dart';

/// Form Buat Klub dan Ubah Klub (Bab 2.2.8 poin 2).
///
/// Buat klub: `ClubFormScreen()`. Setelah tersimpan, panel kode undangan
/// muncul.
/// Ubah klub: `ClubFormScreen(club: club)`. Setelah tersimpan, form ditutup
/// dan mengembalikan [Club] yang sudah diperbarui lewat Navigator.pop.
class ClubFormScreen extends StatefulWidget {
  const ClubFormScreen({super.key, this.club});

  /// Diisi saat mengubah klub. `null` berarti klub baru.
  final Club? club;

  @override
  State<ClubFormScreen> createState() => _ClubFormScreenState();
}

class _ClubFormScreenState extends State<ClubFormScreen> {
  static const int _maxDeskripsi = 200;

  final _formKey = GlobalKey<FormState>();
  final _clubService = ClubService();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();

  late final Future<List<ClubBookOption>> _booksFuture;
  ClubBookOption? _book;
  DateTime? _target;
  bool _bookError = false;
  bool _targetError = false;
  bool _isSaving = false;

  bool get _isEditing => widget.club != null;

  @override
  void initState() {
    super.initState();
    _booksFuture = _clubService.getBookOptions();

    final club = widget.club;
    if (club != null) {
      _namaController.text = club.nama;
      _deskripsiController.text = club.deskripsi;
      _target = club.targetSelesai;
      // Jumlah halaman buku klub tidak disimpan, jadi perkiraan halaman
      // per hari baru muncul jika pengguna memilih ulang buku dari rak.
      _book = ClubBookOption(
        judul: club.judulBuku,
        penulis: '',
        totalHalaman: 0,
        halamanTerakhir: 0,
      );
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  int? get _sisaHari => _target
      ?.difference(DateLabel.dateOnly(DateTime.now()))
      .inDays;

  /// Contoh: "29 hari lagi · sekitar 10 halaman per hari".
  String? get _paceText {
    final days = _sisaHari;
    final book = _book;
    if (days == null || days <= 0) return null;
    final base = '$days hari lagi';
    if (book == null || book.totalHalaman <= 0) return base;
    final perDay = (book.totalHalaman / days).ceil();
    return '$base · sekitar $perDay halaman per hari';
  }

  Future<void> _pickBook() async {
    final books = await _booksFuture.catchError((_) => <ClubBookOption>[]);
    if (!mounted) return;
    final picked = await showModalBottomSheet<ClubBookOption>(
      context: context,
      showDragHandle: true,
      builder: (context) => _BookPickerSheet(books: books),
    );
    if (picked != null) {
      setState(() {
        _book = picked;
        _bookError = false;
      });
    }
  }

  Future<void> _pickTarget() async {
    final today = DateLabel.dateOnly(DateTime.now());
    final firstDate = today.add(const Duration(days: 1));
    final current = _target ?? today.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(firstDate) ? firstDate : current,
      firstDate: firstDate,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Target selesai',
    );
    if (picked != null) {
      setState(() {
        _target = picked;
        _targetError = false;
      });
    }
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState!.validate();
    setState(() {
      _bookError = _book == null;
      _targetError = _target == null;
    });
    if (!formValid || _bookError || _targetError) return;

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        final updated = await _clubService.updateClub(
          clubId: widget.club!.id,
          nama: _namaController.text.trim(),
          deskripsi: _deskripsiController.text.trim(),
          judulBuku: _book!.judul,
          targetSelesai: _target!,
        );
        if (mounted) Navigator.pop(context, updated);
        return;
      }

      final club = await _clubService.createClub(
        nama: _namaController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        judulBuku: _book!.judul,
        targetSelesai: _target!,
      );
      if (!mounted) return;
      await _showCreatedSheet(club);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Perubahan gagal disimpan. Cek koneksi lalu coba lagi.'
              : 'Klub gagal dibuat. Cek koneksi lalu coba lagi.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showCreatedSheet(Club club) async {
    final openClub = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: true,
      builder: (context) => _ClubCreatedSheet(club: club),
    );
    if (!mounted) return;
    if (openClub == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ClubDetailScreen(club: club)),
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Tutup',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEditing ? 'Ubah klub' : 'Buat klub'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            TextFormField(
              controller: _namaController,
              textCapitalization: TextCapitalization.words,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Nama klub',
                hintText: 'Klub Sabtu Pagi',
                counterText: '',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama klub belum diisi' : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _deskripsiController,
              minLines: 3,
              maxLines: 4,
              maxLength: _maxDeskripsi,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Baca santai tiap Sabtu pagi, diskusi tiap selesai 3 bab.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),
            _FieldLabel('Buku yang dibaca', error: _bookError ? 'Pilih buku dari rak' : null),
            _PickerTile(
              onTap: _pickBook,
              hasError: _bookError,
              trailing: const Icon(Icons.chevron_right),
              child: _book == null
                  ? Text('Pilih dari rak buku', style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_book!.judul, style: theme.textTheme.titleSmall),
                        Text(
                          _book!.totalHalaman > 0
                              ? 'Dari rak kamu · ${_book!.totalHalaman} halaman'
                              : 'Ketuk untuk mengganti buku',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            _FieldLabel('Target selesai', error: _targetError ? 'Pilih tanggal target' : null),
            _PickerTile(
              onTap: _pickTarget,
              hasError: _targetError,
              trailing: const Icon(Icons.calendar_today_outlined, size: 20),
              child: Text(
                _target == null ? 'Pilih tanggal' : DateLabel.full(_target!),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _target == null ? colors.onSurfaceVariant : null,
                ),
              ),
            ),
            if (_paceText != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(_paceText!,
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.primary)),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isEditing) ...[
              Text(
                'Kode undangan dibuat otomatis setelah klub disimpan.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
            ],
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Simpan perubahan' : 'Buat klub'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.error});

  final String text;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        error == null ? text : '$text · $error',
        style: theme.textTheme.labelMedium?.copyWith(
          color: error == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.error,
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.onTap,
    required this.child,
    required this.trailing,
    this.hasError = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final Widget trailing;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: hasError ? colors.error : colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(child: child),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookPickerSheet extends StatelessWidget {
  const _BookPickerSheet({required this.books});

  final List<ClubBookOption> books;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (books.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Text(
          'Rak bukumu masih kosong. Tambahkan buku di Rak Buku dulu, '
          'lalu kembali ke sini.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Pilih buku dari rak', style: theme.textTheme.titleMedium),
          ),
          for (final book in books)
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(book.judul),
              subtitle: Text(
                [if (book.penulis.isNotEmpty) book.penulis, '${book.totalHalaman} halaman']
                    .join(' · '),
              ),
              onTap: () => Navigator.pop(context, book),
            ),
        ],
      ),
    );
  }
}

/// Panel "Klub siap!" berisi kode undangan. Mengembalikan `true`
/// jika pengguna menekan Buka klub.
class _ClubCreatedSheet extends StatelessWidget {
  const _ClubCreatedSheet({required this.club});

  final Club club;

  void _copy(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shareText = 'Yuk ikut ${club.nama} di Bacakala! Kita baca '
        '${club.judulBuku} bareng. Masukkan kode ${club.kodeUndangan} di menu Klub.';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colors.primaryContainer,
              child: Icon(Icons.check, color: colors.primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text('${club.nama} siap!', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Bagikan kode ini ke teman yang mau ikut membaca ${club.judulBuku}.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
              decoration: BoxDecoration(
                color: colors.secondaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      club.kodeUndangan,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.primary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                    onPressed: () => _copy(context, club.kodeUndangan, 'Kode disalin'),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Salin'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Buka klub'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _copy(context, shareText, 'Pesan undangan disalin, tinggal tempel di chat'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Bagikan kode'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Nanti saja'),
            ),
          ],
        ),
      ),
    );
  }
}