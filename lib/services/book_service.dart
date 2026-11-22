import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/book.dart';
import 'auth_service.dart';

class BookService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Buku yang sedang dibaca (paling baru). Null jika belum ada.
  Future<Book?> getCurrentlyReading() async {
    try {
      final data = await _client
          .from('books')
          .select()
          .eq('status', 'sedang_dibaca')
          .order('created_at', ascending: false)
          .limit(1);

      if (data.isEmpty) return null;
      return Book.fromJson(data.first);
    } catch (e) {
      throw ServiceException.from(e);
    }
  }

  /// Jumlah buku berstatus 'selesai' pada tahun ini.
  /// Catatan: belum ada kolom tanggal selesai, jadi dipakai created_at.
  Future<int> countFinishedThisYear() async {
    try {
      final awalTahun = DateTime(DateTime.now().year).toUtc().toIso8601String();
      final data = await _client
          .from('books')
          .select('id')
          .eq('status', 'selesai')
          .gte('created_at', awalTahun);
      return data.length;
    } catch (e) {
      throw ServiceException.from(e);
    }
  }
  Future<Book> getBookById(String bookId) async {
    try {
      final data = await _client
          .from('books')
          .select()
          .eq('id', bookId)
          .single();

      return Book.fromJson(data);
    } catch (e) {
      throw ServiceException.from(e);
    }
  }
}
