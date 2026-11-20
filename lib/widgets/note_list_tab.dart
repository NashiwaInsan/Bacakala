import 'package:flutter/material.dart';

import '../models/note.dart';
import '../screens/notes/note_form_screen.dart';
import '../services/note_service.dart';
import '../utils/date_label.dart';

/// Isi tab Catatan di halaman Detail Buku (Bab 2.2.6 poin 1).
///
/// Dipasang di BookDetailScreen, contoh:
///   final _notesKey = GlobalKey<NoteListTabState>();
///   NoteListTab(key: _notesKey, bookId: ..., bookTitle: ...,
///               lastPage: ..., totalPages: ...)
/// Setelah tombol "+ Catatan" membuka form dan kembali, panggil
/// `_notesKey.currentState?.reload()`.
class NoteListTab extends StatefulWidget {
  const NoteListTab({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.lastPage,
    required this.totalPages,
    this.onCountChanged,
  });

  final String bookId;
  final String bookTitle;
  final int lastPage;
  final int totalPages;

  /// Dipanggil setiap jumlah catatan berubah, untuk angka di label tab.
  final ValueChanged<int>? onCountChanged;

  @override
  State<NoteListTab> createState() => NoteListTabState();
}

class NoteListTabState extends State<NoteListTab> {
  final _noteService = NoteService();

  List<Note> _notes = [];
  NoteType? _filter;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final notes = await _noteService.getNotesByBook(widget.bookId);
      if (!mounted) return;
      setState(() => _notes = notes);
      widget.onCountChanged?.call(notes.length);
    } catch (_) {
      if (mounted) setState(() => _error = 'Catatan gagal dimuat.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openNote(Note note) async {
    final result = await Navigator.push<NoteFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteFormScreen(
          bookId: widget.bookId,
          bookTitle: widget.bookTitle,
          lastPage: widget.lastPage,
          totalPages: widget.totalPages,
          note: note,
        ),
      ),
    );
    if (result != null) reload();
  }

  int _countOf(NoteType type) => _notes.where((n) => n.jenis == type).length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return _Message(
        text: _error!,
        action: TextButton(onPressed: reload, child: const Text('Coba lagi')),
      );
    }
    if (_notes.isEmpty) {
      return const _Message(
        text: 'Belum ada catatan. Simpan kutipan atau pikiranmu '
            'lewat tombol + Catatan.',
      );
    }

    final visible = _filter == null
        ? _notes
        : _notes.where((n) => n.jenis == _filter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Semua',
                count: _notes.length,
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              for (final type in NoteType.values)
                _FilterChip(
                  label: type.label,
                  count: _countOf(type),
                  selected: _filter == type,
                  onTap: () => setState(() => _filter = type),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final note in visible) ...[
          note.isKutipan
              ? _QuoteCard(note: note, onTap: () => _openNote(note))
              : _PersonalNoteCard(note: note, onTap: () => _openNote(note)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label  $count'),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/// Kutipan: latar berwarna, huruf miring, nomor halaman di kiri.
class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final date = note.createdAt == null ? '' : ' · ${DateLabel.dayMonth(note.createdAt!)}';

    return Material(
      color: colors.secondaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 16, 14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 48,
                  child: Column(
                    children: [
                      Text('hal', style: theme.textTheme.labelSmall),
                      Text('${note.halaman}', style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
                VerticalDivider(width: 1, color: colors.outlineVariant),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '“${note.isi}”',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Kutipan$date', style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalNoteCard extends StatelessWidget {
  const _PersonalNoteCard({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined, size: 14, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Catatan pribadi · hal ${note.halaman}',
                    style: theme.textTheme.labelSmall?.copyWith(color: colors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(note.isi, style: theme.textTheme.bodyMedium),
              if (note.createdAt != null) ...[
                const SizedBox(height: 8),
                Text(DateLabel.dayMonth(note.createdAt!), style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
