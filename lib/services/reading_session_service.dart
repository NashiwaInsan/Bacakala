import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bacakala/models/reading_session.dart';
import 'package:bacakala/services/auth_service.dart';

class ReadingSessionService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Ambil daftar riwayat sesi membaca untuk satu buku (terbaru di atas).
  Future<List<ReadingSession>> getSessionsByBook(String bookId) async {
    try {
      final data = await _client
          .from('reading_sessions')
          .select()
          .eq('book_id', bookId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => ReadingSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServiceException.from(e);
    }
  }

  /// Simpan sesi membaca baru.
  /// Trigger `on_reading_session_created` di Supabase akan otomatis
  /// memperbarui `halaman_terakhir` & `status` pada tabel `books`.
  Future<void> createSession({
    required String bookId,
    required int halamanAwal,
    required int halamanAkhir,
    required int durasiMenit,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const ServiceException('Sesi login berakhir. Silakan masuk ulang.');
      }

      await _client.from('reading_sessions').insert({
        'book_id': bookId,
        'user_id': userId,
        'halaman_awal': halamanAwal,
        'halaman_akhir': halamanAkhir,
        'durasi_menit': durasiMenit,
      });
    } catch (e) {
      throw ServiceException.from(e);
    }
  }
}