import 'package:supabase_flutter/supabase_flutter.dart';

/// Error ramah pengguna. Semua service melempar ini, bukan error mentah.
class ServiceException implements Exception {
  final String message;
  const ServiceException(this.message);

  /// Ubah error apa pun (Supabase, jaringan, dll.) jadi pesan bahasa Indonesia.
  factory ServiceException.from(Object error) {
    if (error is ServiceException) return error;

    final teks = error.toString().toLowerCase();

    // Masalah jaringan
    if (teks.contains('socketexception') ||
        teks.contains('failed host lookup') ||
        teks.contains('clientexception') ||
        teks.contains('xmlhttprequest') ||
        teks.contains('network') ||
        teks.contains('timeout')) {
      return const ServiceException('Tidak ada koneksi internet');
    }

    if (error is AuthException) {
      final pesan = error.message.toLowerCase();
      final kode = (error.code ?? '').toLowerCase();
      if (pesan.contains('invalid login credentials') ||
          kode == 'invalid_credentials') {
        return const ServiceException('Email atau kata sandi salah');
      }
      if (pesan.contains('already registered') ||
          kode == 'user_already_exists' ||
          kode == 'email_exists') {
        return const ServiceException('Email sudah terdaftar');
      }
      if (pesan.contains('email not confirmed') ||
          kode == 'email_not_confirmed') {
        return const ServiceException(
          'Email belum dikonfirmasi, cek kotak masukmu',
        );
      }
      if (kode == 'weak_password' || pesan.contains('password should be')) {
        return const ServiceException('Kata sandi terlalu lemah');
      }
      if (pesan.contains('rate limit') || kode.contains('rate_limit')) {
        return const ServiceException(
          'Terlalu banyak percobaan, coba lagi nanti',
        );
      }
      if (pesan.contains('invalid') && pesan.contains('email')) {
        return const ServiceException('Format email tidak valid');
      }
      return const ServiceException('Gagal masuk, coba lagi');
    }

    if (error is PostgrestException) {
      // 42P01 / PGRST205 = tabel belum ada
      if (error.code == '42P01' || error.code == 'PGRST205') {
        return const ServiceException(
          'Data belum tersedia (tabel belum dibuat di Supabase)',
        );
      }
      return const ServiceException('Gagal memuat data, coba lagi');
    }

    return const ServiceException('Terjadi kesalahan, coba lagi');
  }

  @override
  String toString() => message;
}

/// Semua urusan login/daftar/keluar lewat sini.
class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  /// Stream setiap kali status login berubah.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Daftar akun baru. Nama dikirim lewat metadata agar trigger di database
  /// bisa membuat baris profil otomatis.
  /// Mengembalikan true jika langsung punya sesi (tanpa konfirmasi email).
  Future<bool> signUp(String nama, String email, String password) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'nama': nama},
      );
      return res.session != null;
    } catch (e) {
      throw ServiceException.from(e);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw ServiceException.from(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw ServiceException.from(e);
    }
  }
}
