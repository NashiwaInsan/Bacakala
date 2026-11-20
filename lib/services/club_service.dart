import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/club.dart';
import '../models/club_post.dart';
import '../utils/date_label.dart';

/// Dilempar saat kode undangan tidak ditemukan.
class ClubNotFoundException implements Exception {
  const ClubNotFoundException();
}

/// Operasi fitur Klub Baca (Bab 2.2.8).
///
/// Buat klub, gabung, dan progres anggota memakai fungsi database
/// (`create_club`, `join_club`, `get_club_progress`) karena RLS
/// melarang non-anggota membaca tabel `clubs` dan melarang pengguna
/// membaca buku milik orang lain. Lihat supabase/club_functions.sql.
class ClubService {
  ClubService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('Sesi login berakhir. Silakan masuk lagi.');
    }
    return user.id;
  }

  /// Klub yang diikuti pengguna, target terdekat di atas,
  /// lengkap dengan jumlah anggota dan progres pengguna.
  Future<List<Club>> getMyClubs() async {
    final rows = await _client
        .from('club_members')
        .select('clubs(*, club_members(count))')
        .eq('user_id', _userId);

    final clubs = rows
        .map((row) => row['clubs'])
        .whereType<Map<String, dynamic>>()
        .map(Club.fromJson)
        .toList()
      ..sort((a, b) => a.targetSelesai.compareTo(b.targetSelesai));

    final progressByTitle = await _myProgressByTitle();
    return clubs
        .map((c) => c.withProgress(progressByTitle[c.judulBuku.toLowerCase()] ?? 0))
        .toList();
  }

  /// Progres pengguna per judul buku di raknya sendiri.
  Future<Map<String, int>> _myProgressByTitle() async {
    final books = await _client
        .from('books')
        .select('judul, total_halaman, halaman_terakhir');
    return {
      for (final b in books)
        (b['judul'] as String).toLowerCase(): _percent(
          (b['halaman_terakhir'] as int?) ?? 0,
          b['total_halaman'] as int,
        ),
    };
  }

  int _percent(int page, int total) =>
      total <= 0 ? 0 : (page * 100 / total).clamp(0, 100).round();

  /// Buku di rak pengguna untuk pilihan "Buku yang dibaca".
  Future<List<ClubBookOption>> getBookOptions() async {
    final rows = await _client
        .from('books')
        .select('judul, penulis, total_halaman, halaman_terakhir')
        .neq('status', 'selesai')
        .order('judul');
    return rows.map(ClubBookOption.fromJson).toList();
  }

  /// Membuat klub. Database membuat kode undangan dan menjadikan
  /// pengguna sebagai owner.
  Future<Club> createClub({
    required String nama,
    required String deskripsi,
    required String judulBuku,
    required DateTime targetSelesai,
  }) async {
    final row = await _client.rpc('create_club', params: {
      'p_nama': nama,
      'p_deskripsi': deskripsi,
      'p_judul_buku': judulBuku,
      'p_target_selesai': DateLabel.isoDate(targetSelesai),
    });
    return Club.fromJson(Map<String, dynamic>.from(row as Map));
  }

  /// Bergabung lewat kode undangan, misalnya KSM-4821.
  Future<Club> joinClub(String kode) async {
    try {
      final row = await _client.rpc('join_club', params: {
        'p_kode': kode.trim().toUpperCase(),
      });
      return Club.fromJson(Map<String, dynamic>.from(row as Map));
    } on PostgrestException catch (e) {
      if (e.message.contains('KODE_TIDAK_DITEMUKAN')) {
        throw const ClubNotFoundException();
      }
      rethrow;
    }
  }

  /// Progres membaca setiap anggota, tertinggi di atas.
  Future<List<ClubMemberProgress>> getMemberProgress(String clubId) async {
    final rows = await _client.rpc('get_club_progress', params: {
      'p_club_id': clubId,
    }) as List<dynamic>;
    return rows
        .map((r) => ClubMemberProgress.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  /// Postingan diskusi, terlama di atas seperti percakapan.
  Future<List<ClubPost>> getPosts(String clubId) async {
    final rows = await _client
        .from('club_posts')
        .select('id, club_id, user_id, isi, created_at, profiles(nama)')
        .eq('club_id', clubId)
        .order('created_at');
    return rows.map(ClubPost.fromJson).toList();
  }

  Future<ClubPost> addPost(String clubId, String isi) async {
    final row = await _client
        .from('club_posts')
        .insert({'club_id': clubId, 'user_id': _userId, 'isi': isi.trim()})
        .select('id, club_id, user_id, isi, created_at, profiles(nama)')
        .single();
    return ClubPost.fromJson(row);
  }

  String get currentUserId => _userId;
}
