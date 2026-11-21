import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'auth_service.dart';

/// Pengaturan pengingat membaca: aktif atau tidak, dan jamnya.
typedef ReminderSetting = ({bool aktif, int jam, int menit});

/// Pengingat membaca harian lewat notifikasi lokal (tanpa server).
///
/// Pengaturan disimpan di perangkat dengan shared_preferences, bukan di
/// Supabase, karena pengingat berlaku per perangkat. Penjadwalan hanya
/// berjalan di Android; di web hanya pengaturannya yang bisa dilihat.
class ReminderService {
  static const _kAktif = 'pengingat_aktif';
  static const _kJam = 'pengingat_jam';
  static const _kMenit = 'pengingat_menit';
  static const _idNotifikasi = 1;

  static const jamAwal = 19;
  static const menitAwal = 30;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _siap = false;

  /// Notifikasi terjadwal hanya didukung di Android.
  static bool get didukung =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Contoh: 19.30
  static String formatJam(int jam, int menit) =>
      '${jam.toString().padLeft(2, '0')}.${menit.toString().padLeft(2, '0')}';

  Future<ReminderSetting> muat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (
        aktif: prefs.getBool(_kAktif) ?? false,
        jam: prefs.getInt(_kJam) ?? jamAwal,
        menit: prefs.getInt(_kMenit) ?? menitAwal,
      );
    } catch (_) {
      // Penyimpanan tidak bisa dibaca: pakai bawaan, pengingat dianggap mati.
      return (aktif: false, jam: jamAwal, menit: menitAwal);
    }
  }

  Future<void> _siapkan() async {
    if (_siap) return;
    // Zona waktu perangkat, supaya jam 19.30 berarti 19.30 waktu setempat.
    tzdata.initializeTimeZones();
    final zona = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zona.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _siap = true;
  }

  /// Nyalakan pengingat setiap hari pada [jam]:[menit].
  /// Mengembalikan false jika izin notifikasi ditolak pengguna.
  /// Juga dipakai untuk mengubah jam saat pengingat sudah menyala.
  Future<bool> aktifkan(int jam, int menit) async {
    if (!didukung) {
      throw const ServiceException(
        'Pengingat hanya tersedia di aplikasi Android',
      );
    }
    try {
      await _siapkan();

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final izin = await android?.requestNotificationsPermission();
      if (izin == false) return false;

      final sekarang = tz.TZDateTime.now(tz.local);
      var waktu = tz.TZDateTime(
        tz.local,
        sekarang.year,
        sekarang.month,
        sekarang.day,
        jam,
        menit,
      );
      if (!waktu.isAfter(sekarang)) {
        waktu = waktu.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: _idNotifikasi,
        title: 'Waktunya membaca',
        body: 'Luangkan beberapa menit untuk bukumu hari ini.',
        scheduledDate: waktu,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'pengingat_membaca',
            'Pengingat membaca',
            channelDescription: 'Pengingat harian untuk membaca buku',
          ),
        ),
        // Tidak eksak: tidak perlu izin alarm khusus, selisih beberapa menit
        // tidak masalah untuk pengingat membaca.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      await _simpan(aktif: true, jam: jam, menit: menit);
      return true;
    } catch (e) {
      throw ServiceException.from(e);
    }
  }

  Future<void> matikan() async {
    try {
      if (didukung) {
        await _siapkan();
        await _plugin.cancel(id: _idNotifikasi);
      }
      final lama = await muat();
      await _simpan(aktif: false, jam: lama.jam, menit: lama.menit);
    } catch (e) {
      throw ServiceException.from(e);
    }
  }

  Future<void> _simpan({
    required bool aktif,
    required int jam,
    required int menit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAktif, aktif);
    await prefs.setInt(_kJam, jam);
    await prefs.setInt(_kMenit, menit);
  }
}
