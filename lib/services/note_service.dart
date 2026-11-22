import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/note.dart';

/// Operasi CRUD untuk tabel `notes`.
///
/// RLS di Supabase sudah membatasi akses ke baris milik pengguna sendiri,
/// jadi service ini cukup mengisi `user_id` saat menambah catatan.
class NoteService {
  NoteService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'notes';

  String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('Sesi login berakhir. Silakan masuk lagi.');
    }
    return user.id;
  }

  /// Semua catatan milik satu buku, terbaru di atas.
  /// Isi [jenis] untuk filter Kutipan atau Catatan pribadi.
  Future<List<Note>> getNotesByBook(String bookId, {NoteType? jenis}) async {
    var query = _client.from(_table).select().eq('book_id', bookId);
    if (jenis != null) {
      query = query.eq('jenis', jenis.value);
    }
    final rows = await query.order('created_at', ascending: false);
    return rows.map(Note.fromJson).toList();
  }

  /// Menyimpan catatan baru dan mengembalikan baris yang tersimpan
  /// (sudah berisi `id` dan `created_at`).
  Future<Note> addNote(Note note) async {
    final row = await _client
        .from(_table)
        .insert({...note.toJson(), 'user_id': _userId})
        .select()
        .single();
    return Note.fromJson(row);
  }

  Future<Note> updateNote(Note note) async {
    final id = note.id;
    if (id == null) {
      throw ArgumentError('Catatan belum punya id, pakai addNote().');
    }
    final row = await _client
        .from(_table)
        .update(note.toJson())
        .eq('id', id)
        .select()
        .single();
    return Note.fromJson(row);
  }

  Future<void> deleteNote(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
