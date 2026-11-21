import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import 'auth_service.dart';

/// Ringkasan jumlah buku milik user per status (untuk kartu target di Profil).
typedef ReadingSummary = ({int selesai, int sedangDibaca, int inginDibaca});

class ProfileService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Hitung jumlah buku per status milik user yang sedang login.
  /// Satu query saja, lalu dihitung di aplikasi.
  Future<ReadingSummary> getReadingSummary() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return (selesai: 0, sedangDibaca: 0, inginDibaca: 0);
      }

      final data = await _client
          .from('books')
          .select('status')
          .eq('user_id', user.id);

      var selesai = 0;
      var sedangDibaca = 0;
      var inginDibaca = 0;
      for (final baris in data) {
        switch (baris['status']) {
          case 'selesai':
            selesai++;
          case 'sedang_dibaca':
            sedangDibaca++;
          case 'ingin_dibaca':
            inginDibaca++;
        }
      }
      return (
        selesai: selesai,
        sedangDibaca: sedangDibaca,
        inginDibaca: inginDibaca,
      );
    } catch (e) {
      throw ServiceException.from(e);
    }
  }

  /// Ambil profil milik user yang sedang login (null jika belum ada barisnya).
  Future<Profile?> getMyProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return data == null ? null : Profile.fromJson(data);
    } catch (e) {
      throw ServiceException.from(e);
    }
  }

  /// Ubah nama dan/atau target buku tahunan milik user yang sedang login.
  /// Hanya kolom yang diisi (tidak null) yang diubah.
  /// Mengembalikan profil terbaru dari database.
  Future<Profile> updateProfile({String? nama, int? targetTahunan}) async {
    assert(
      nama != null || targetTahunan != null,
      'Isi minimal satu kolom yang diubah',
    );
    try {
      final user = _client.auth.currentUser!;
      final perubahan = <String, dynamic>{
        'nama': ?nama?.trim(),
        'target_tahunan': ?targetTahunan,
      };

      // .single() gagal jika tidak ada baris yang terubah (mis. baris profil
      // belum dibuat trigger, atau RLS menolak), sehingga error tidak diam-diam.
      final data = await _client
          .from('profiles')
          .update(perubahan)
          .eq('id', user.id)
          .select()
          .single();

      return Profile.fromJson(data);
    } catch (e) {
      throw ServiceException.from(e);
    }
  }
}