import 'package:material_ui/material_ui.dart';

import '../../services/auth_service.dart';
import '../../services/reminder_service.dart';
import '../../theme/app_theme.dart';

/// Halaman Pengingat membaca: saklar aktif dan pilihan jam harian.
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final _service = ReminderService();

  bool _memuat = true;
  bool _bekerja = false;
  bool _aktif = false;
  int _jam = ReminderService.jamAwal;
  int _menit = ReminderService.menitAwal;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final s = await _service.muat();
    if (!mounted) return;
    setState(() {
      _aktif = s.aktif;
      _jam = s.jam;
      _menit = s.menit;
      _memuat = false;
    });
  }

  Future<void> _ubahSaklar(bool nyala) async {
    setState(() {
      _bekerja = true;
      _error = null;
    });
    try {
      if (nyala) {
        final diizinkan = await _service.aktifkan(_jam, _menit);
        if (!mounted) return;
        if (!diizinkan) {
          setState(() {
            _error =
                'Izin notifikasi ditolak. Aktifkan lewat pengaturan HP '
                'agar pengingat bisa muncul.';
          });
          return;
        }
      } else {
        await _service.matikan();
      }
      if (mounted) setState(() => _aktif = nyala);
    } on ServiceException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _bekerja = false);
    }
  }

  Future<void> _pilihJam() async {
    final dipilih = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _jam, minute: _menit),
      helpText: 'Pilih jam pengingat',
    );
    if (dipilih == null || !mounted) return;

    setState(() {
      _bekerja = true;
      _error = null;
    });
    try {
      // Saat pengingat menyala, jadwal diganti. Saat mati, jam hanya disimpan
      // dan dipakai ketika pengingat dinyalakan.
      if (_aktif) {
        await _service.aktifkan(dipilih.hour, dipilih.minute);
      }
      if (mounted) {
        setState(() {
          _jam = dipilih.hour;
          _menit = dipilih.minute;
        });
      }
    } on ServiceException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _bekerja = false);
    }
  }

  BoxDecoration get _kartu => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
    border: Border.all(color: AppColors.border),
  );

  @override
  Widget build(BuildContext context) {
    final didukung = ReminderService.didukung;
    final bisaDiubah = didukung && !_bekerja && !_memuat;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenPadding,
            8,
            AppSizes.screenPadding,
            AppSizes.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(-12, 0),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 32,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Pengingat membaca', style: AppText.display),
              const SizedBox(height: 10),
              Text(
                'Dapatkan pengingat setiap hari supaya waktu membacamu '
                'tidak terlewat.',
                style: AppText.subtitle,
              ),
              const SizedBox(height: 28),
              Container(
                decoration: _kartu,
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _aktif,
                      onChanged: bisaDiubah ? _ubahSaklar : null,
                      activeThumbColor: AppColors.primary,
                      title: Text('Ingatkan saya', style: AppText.bodyStrong),
                      subtitle: Text(
                        _aktif ? 'Menyala' : 'Mati',
                        style: AppText.caption,
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      enabled: bisaDiubah,
                      onTap: bisaDiubah ? _pilihJam : null,
                      title: Text('Jam', style: AppText.bodyStrong),
                      subtitle: Text(
                        'Setiap hari, ${ReminderService.formatJam(_jam, _menit)}',
                        style: AppText.caption,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (!didukung) ...[
                const SizedBox(height: 16),
                Text(
                  'Pengingat hanya tersedia di aplikasi Android. '
                  'Di browser, pengaturan ini hanya bisa dilihat.',
                  style: AppText.hint,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: AppText.body.copyWith(color: AppColors.danger),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
