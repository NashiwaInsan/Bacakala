import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../models/note.dart';
import '../../services/note_service.dart';

/// Hasil yang dikirim balik ke Detail Buku lewat Navigator.pop,
/// supaya tab Catatan tahu harus memuat ulang daftar.
enum NoteFormResult { saved, deleted }

/// Form tambah dan ubah catatan (Bab 2.2.6 poin 2).
///
/// Tambah:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => NoteFormScreen(
///       bookId: book.id, bookTitle: book.judul,
///       lastPage: book.halamanTerakhir, totalPages: book.totalHalaman)));
///
/// Ubah: kirim juga `note: catatanYangDiketuk`.
class NoteFormScreen extends StatefulWidget {
  const NoteFormScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.lastPage,
    required this.totalPages,
    this.note,
    this.initialType = NoteType.kutipan,
  });

  final String bookId;
  final String bookTitle;

  /// Halaman terakhir yang dibaca, ditampilkan sebagai acuan.
  final int lastPage;
  final int totalPages;

  /// Diisi saat mengubah catatan. `null` berarti catatan baru.
  final Note? note;

  /// Jenis awal untuk catatan baru, misalnya Kutipan saat dibuka
  /// dari tombol Kutipan di Sesi Membaca.
  final NoteType initialType;

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteService = NoteService();

  late final TextEditingController _isiController;
  late final TextEditingController _halamanController;
  late NoteType _jenis;
  bool _isBusy = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _jenis = note?.jenis ?? widget.initialType;
    _isiController = TextEditingController(text: note?.isi ?? '');
    _halamanController = TextEditingController(
      text: '${note?.halaman ?? widget.lastPage}',
    );
  }

  @override
  void dispose() {
    _isiController.dispose();
    _halamanController.dispose();
    super.dispose();
  }

  String? _validateIsi(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Isi catatan belum ditulis';
    }
    return null;
  }

  String? _validateHalaman(String? value) {
    final halaman = int.tryParse(value ?? '');
    if (halaman == null) return 'Isi nomor halaman';
    if (halaman < 1 || halaman > widget.totalPages) {
      return 'Halaman 1–${widget.totalPages}';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final draft = Note(
      id: widget.note?.id,
      bookId: widget.bookId,
      halaman: int.parse(_halamanController.text),
      jenis: _jenis,
      isi: _isiController.text.trim(),
      createdAt: widget.note?.createdAt,
    );

    await _run(() async {
      if (_isEditing) {
        await _noteService.updateNote(draft);
      } else {
        await _noteService.addNote(draft);
      }
      if (mounted) Navigator.pop(context, NoteFormResult.saved);
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan ini?'),
        content: Text(
          '${_jenis.label} di halaman ${widget.note!.halaman} akan dihapus '
          'permanen dan tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(() async {
      await _noteService.deleteNote(widget.note!.id!);
      if (mounted) Navigator.pop(context, NoteFormResult.deleted);
    });
  }

  /// Menjalankan aksi ke Supabase sambil mengunci tombol,
  /// lalu menampilkan pesan jika gagal.
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isBusy = true);
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan gagal disimpan. Cek koneksi lalu coba lagi.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showPhotoComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto halaman segera hadir.')),
    );
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
        title: Text(_isEditing ? 'Ubah catatan' : 'Catatan baru'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.error),
              tooltip: 'Hapus catatan',
              onPressed: _isBusy ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            _BookReference(
              title: widget.bookTitle,
              lastPage: widget.lastPage,
            ),
            const SizedBox(height: 16),
            SegmentedButton<NoteType>(
              segments: const [
                ButtonSegment(
                  value: NoteType.kutipan,
                  icon: Icon(Icons.format_quote),
                  label: Text('Kutipan'),
                ),
                ButtonSegment(
                  value: NoteType.catatan,
                  icon: Icon(Icons.description_outlined),
                  label: Text('Catatan pribadi'),
                ),
              ],
              selected: {_jenis},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _jenis = selection.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isiController,
              validator: _validateIsi,
              minLines: 6,
              maxLines: 10,
              maxLength: Note.maxIsiLength,
              textCapitalization: TextCapitalization.sentences,
              style: _jenis == NoteType.kutipan
                  ? theme.textTheme.titleMedium
                      ?.copyWith(fontStyle: FontStyle.italic, height: 1.5)
                  : theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: _jenis == NoteType.kutipan
                    ? 'Salin kalimat dari buku…'
                    : 'Tulis pikiranmu tentang bagian ini…',
                alignLabelWithHint: true,
                filled: _jenis == NoteType.kutipan,
                fillColor: colors.secondaryContainer.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _halamanController,
                    validator: _validateHalaman,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Halaman'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _showPhotoComingSoon,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Foto halaman'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(
          onPressed: _isBusy ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: _isBusy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Simpan perubahan' : 'Simpan catatan'),
        ),
      ),
    );
  }
}

/// Judul buku dan halaman terakhir sebagai acuan mengisi nomor halaman.
class _BookReference extends StatelessWidget {
  const _BookReference({required this.title, required this.lastPage});

  final String title;
  final int lastPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 24,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'sedang di halaman $lastPage',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
