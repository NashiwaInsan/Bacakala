import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../models/club.dart';
import '../../models/club_post.dart';
import '../../services/club_service.dart';
import '../../utils/date_label.dart';
import 'club_form_screen.dart';

/// Aksi di menu titik tiga Detail Klub.
enum _ClubAction { ubah, hapus, keluar }

/// Halaman Detail Klub (Bab 2.2.8 poin 3): buku bersama, progres
/// anggota, dan ruang diskusi.
class ClubDetailScreen extends StatefulWidget {
  const ClubDetailScreen({super.key, required this.club});

  final Club club;

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  final _clubService = ClubService();
  final _postController = TextEditingController();

  List<ClubMemberProgress> _members = [];
  List<ClubPost> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSending = false;

  /// Disalin dari widget supaya bisa diganti setelah klub diubah.
  late Club club;

  bool get _isOwner => club.ownerId == _clubService.currentUserId;

  @override
  void initState() {
    super.initState();
    club = widget.club;
    _load();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        _clubService.getMemberProgress(club.id),
        _clubService.getPosts(club.id),
      ]);
      if (!mounted) return;
      setState(() {
        _members = results[0] as List<ClubMemberProgress>;
        _posts = results[1] as List<ClubPost>;
      });
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _send() async {
    final text = _postController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      final post = await _clubService.addPost(club.id, text);
      _postController.clear();
      if (mounted) setState(() => _posts = [..._posts, post]);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesan gagal dikirim. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Dialog konfirmasi standar; mengembalikan true jika pengguna setuju.
  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
                minimumSize: const Size(0, 40),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        );
      },
    );
    return ok == true;
  }

  Future<void> _onAction(_ClubAction action) async {
    switch (action) {
      case _ClubAction.ubah:
        final updated = await Navigator.push<Club>(
          context,
          MaterialPageRoute(builder: (_) => ClubFormScreen(club: club)),
        );
        if (updated != null && mounted) {
          setState(() => club = updated);
          _showMessage('Klub diperbarui');
          _load();
        }
      case _ClubAction.hapus:
        final ok = await _confirm(
          title: 'Hapus klub ini?',
          message: '${club.nama} beserta semua anggota dan diskusinya akan '
              'dihapus permanen.',
          action: 'Hapus',
        );
        if (!ok) return;
        await _leavePage(
          () => _clubService.deleteClub(club.id),
          'Klub gagal dihapus. Coba lagi.',
        );
      case _ClubAction.keluar:
        final ok = await _confirm(
          title: 'Keluar dari klub?',
          message: 'Kamu bisa bergabung lagi nanti dengan kode '
              '${club.kodeUndangan}.',
          action: 'Keluar',
        );
        if (!ok) return;
        await _leavePage(
          () => _clubService.leaveClub(club.id),
          'Gagal keluar dari klub. Coba lagi.',
        );
    }
  }

  /// Menjalankan hapus/keluar, lalu kembali ke Daftar Klub.
  Future<void> _leavePage(Future<void> Function() action, String errorText) async {
    try {
      await action();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) _showMessage(errorText);
    }
  }

  Future<void> _deletePost(ClubPost post) async {
    final ok = await _confirm(
      title: 'Hapus pesan ini?',
      message: 'Pesan akan dihapus dari diskusi klub.',
      action: 'Hapus',
    );
    if (!ok) return;
    try {
      await _clubService.deletePost(post.id);
      if (mounted) setState(() => _posts = _posts.where((p) => p.id != post.id).toList());
    } catch (_) {
      if (mounted) _showMessage('Pesan gagal dihapus. Coba lagi.');
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: club.kodeUndangan));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kode undangan disalin')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myId = _clubService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(club.nama),
        actions: [
          PopupMenuButton<_ClubAction>(
            tooltip: 'Menu klub',
            onSelected: _onAction,
            itemBuilder: (context) => _isOwner
                ? const [
                    PopupMenuItem(value: _ClubAction.ubah, child: Text('Ubah klub')),
                    PopupMenuItem(value: _ClubAction.hapus, child: Text('Hapus klub')),
                  ]
                : const [
                    PopupMenuItem(value: _ClubAction.keluar, child: Text('Keluar dari klub')),
                  ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            _SharedBookCard(club: club, onCopyCode: _copyCode),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_hasError)
              Column(
                children: [
                  const Text('Data klub gagal dimuat.'),
                  TextButton(onPressed: _load, child: const Text('Coba lagi')),
                ],
              )
            else ...[
              Row(
                children: [
                  Expanded(child: Text('Progres anggota', style: theme.textTheme.titleMedium)),
                  Text('${_members.length} orang', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 10),
              _MemberProgressCard(members: _members, myId: myId),
              const SizedBox(height: 24),
              Text('Diskusi', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              if (_posts.isEmpty)
                Text(
                  'Belum ada diskusi. Mulai obrolan tentang bab yang baru kamu baca.',
                  style: theme.textTheme.bodyMedium,
                )
              else
                for (final post in _posts) ...[
                  _PostTile(
                    post: post,
                    isMine: post.userId == myId,
                    // Tekan lama untuk menghapus: pesan sendiri, atau semua
                    // pesan jika pengguna owner klub.
                    onLongPress: post.userId == myId || _isOwner
                        ? () => _deletePost(post)
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: _PostComposer(
        controller: _postController,
        isSending: _isSending,
        onSend: _send,
      ),
    );
  }
}

class _SharedBookCard extends StatelessWidget {
  const _SharedBookCard({required this.club, required this.onCopyCode});

  final Club club;
  final VoidCallback onCopyCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sisa = club.sisaHari();
    final sisaText = club.isSelesai
        ? 'periode selesai'
        : sisa == 0
            ? 'hari ini'
            : '$sisa hari lagi';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 84,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.tertiary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              club.judulBuku,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.onTertiary, fontSize: 8, height: 1.2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BUKU BERSAMA',
                    style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(club.judulBuku, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Target selesai ${DateLabel.dayMonth(club.targetSelesai)} · $sisaText',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onCopyCode,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: colors.surface,
                  ),
                  icon: const Icon(Icons.copy, size: 14),
                  label: Text(club.kodeUndangan),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberProgressCard extends StatelessWidget {
  const _MemberProgressCard({required this.members, required this.myId});

  final List<ClubMemberProgress> members;
  final String myId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          for (final m in members)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _Avatar(name: m.nama),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 72,
                    child: Text(
                      m.userId == myId ? 'Kamu' : m.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: m.userId == myId ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: m.persen / 100,
                        minHeight: 6,
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${m.persen}%',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post, required this.isMine, this.onLongPress});

  final ClubPost post;
  final bool isMine;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: _content(theme),
    );
  }

  Widget _content(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(name: post.namaPenulis),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(isMine ? 'Kamu' : post.namaPenulis, style: theme.textTheme.labelLarge),
                  const SizedBox(width: 6),
                  Text(DateLabel.relative(post.createdAt), style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 2),
              Text(post.isi, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = [colors.primary, colors.tertiary, colors.secondary, colors.error];
    final color = palette[name.hashCode.abs() % palette.length];
    return CircleAvatar(
      radius: 16,
      backgroundColor: color,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PostComposer extends StatelessWidget {
  const _PostComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Tulis sesuatu untuk klub…',
                    counterText: '',
                    filled: true,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: isSending ? null : onSend,
                tooltip: 'Kirim',
                icon: isSending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}