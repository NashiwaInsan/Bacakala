import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/book.dart';
import 'auth_service.dart';

class BookService {
  SupabaseClient get _client => Supabase.instance.client;

  static const _bucketSampul = 'covers';

  /// Semua buku milik user yang login, terbaru di atas.
  /// RLS sudah membatasi baris ke pemiliknya.
  Future<List<Book>> getAllBooks() async {
    try {
      final data = await _client
          .from('books')
          .select()
          .order('created_at', ascending: false);
      return data.map(Book.fromJson).toList();
    } catch (e) {
      throw ServiceException.from(e);
    }
  }

  /// Simpan buku baru ke rak dan kembalikan baris yang tersimpan.
  Future<Book> addBook({
    required String judul,
    required String penulis,
    required int totalHalaman,
    required int halamanTerakhir,
    required String status,
    String? coverUrl,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const ServiceException('Sesi berakhir, silakan masuk lagi');
      }

      final baris = <String, dynamic>{
        'user_id': user.id,
        'judul': judul.trim(),
        'penulis': penulis.trim(),
        'total_halaman': totalHalaman,
        'halaman_terakhir': halamanTerakhir,
        'status': status,
        'cover_url': ?coverUrl,
      };

      if (status != 'selesai') return await _insert(baris);

      // Buku selesai: isi tanggal_selesai. Kalau kolomnya belum dibuat
      // (migrasi belum dijalankan), simpan ulang tanpa kolom itu.
      try {
        return await _insert({
          ...baris,
          'tanggal_selesai': DateTime.now().toUtc().toIso8601String(),
        });
      } on PostgrestException catch (e) {
        if (e.code != 'PGRST204') rethrow; // PGRST204 = kolom tidak ditemukan
        return await _insert(baris);
      }
    } catch (e) {
      final pesan = ServiceException.from(e).message;
      // Pesan umum Postgrest untuk memuat data, tidak cocok saat menyimpan.
      throw ServiceException(
        pesan == 'Gagal memuat data, coba lagi'
            ? 'Gagal menyimpan buku, coba lagi'
            : pesan,
      );
    }
  }

  Future<Book> _insert(Map<String, dynamic> baris) async {
    final data = await _client.from('books').insert(baris).select().single();
    return Book.fromJson(data);
  }

  /// Unggah foto sampul ke Storage (bucket `covers`) dan kembalikan tautan
  /// publiknya. Memakai bytes (bukan File) supaya jalan di web dan Android.
  /// [ext] adalah ekstensi file tanpa titik, mis. `jpg`.
  Future<String> uploadCover(Uint8List bytes, String ext) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const ServiceException('Sesi berakhir, silakan masuk lagi');
      }
      final e = ext.toLowerCase();
      final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$e';
      await _client.storage
          .from(_bucketSampul)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: _tipeGambar(e)),
          );
      return _client.storage.from(_bucketSampul).getPublicUrl(path);
    } catch (e) {
      throw ServiceException.from(e);
    }
  }

  String _tipeGambar(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

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
}
