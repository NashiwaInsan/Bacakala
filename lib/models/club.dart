import '../utils/date_label.dart';

/// Satu baris pada tabel `clubs`, ditambah info untuk kartu Daftar Klub.
class Club {
  const Club({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.judulBuku,
    required this.targetSelesai,
    required this.kodeUndangan,
    required this.ownerId,
    this.jumlahAnggota,
    this.progresSaya,
  });

  final String id;
  final String nama;
  final String deskripsi;
  final String judulBuku;
  final DateTime targetSelesai;
  final String kodeUndangan;
  final String ownerId;

  /// Diisi saat diambil untuk Daftar Klub.
  final int? jumlahAnggota;

  /// Persentase progres pengguna pada buku klub (0–100).
  final int? progresSaya;

  int sisaHari({DateTime? now}) => DateLabel.dateOnly(targetSelesai)
      .difference(DateLabel.dateOnly(now ?? DateTime.now()))
      .inDays;

  /// Klub dianggap selesai setelah melewati target selesai.
  bool get isSelesai => sisaHari() < 0;

  factory Club.fromJson(Map<String, dynamic> json) {
    final members = json['club_members'];
    return Club(
      id: json['id'].toString(),
      nama: json['nama'] as String,
      deskripsi: (json['deskripsi'] as String?) ?? '',
      judulBuku: json['judul_buku'] as String,
      targetSelesai: DateTime.parse(json['target_selesai'] as String),
      kodeUndangan: json['kode_undangan'] as String,
      ownerId: json['owner_id'].toString(),
      // Hasil select `club_members(count)` berbentuk [{count: 6}].
      jumlahAnggota: members is List && members.isNotEmpty
          ? members.first['count'] as int?
          : null,
    );
  }

  Club withProgress(int? progres) => Club(
        id: id,
        nama: nama,
        deskripsi: deskripsi,
        judulBuku: judulBuku,
        targetSelesai: targetSelesai,
        kodeUndangan: kodeUndangan,
        ownerId: ownerId,
        jumlahAnggota: jumlahAnggota,
        progresSaya: progres,
      );
}

/// Progres satu anggota di Detail Klub, dari fungsi `get_club_progress`.
class ClubMemberProgress {
  const ClubMemberProgress({
    required this.userId,
    required this.nama,
    required this.persen,
  });

  final String userId;
  final String nama;
  final int persen;

  factory ClubMemberProgress.fromJson(Map<String, dynamic> json) {
    return ClubMemberProgress(
      userId: json['user_id'].toString(),
      nama: json['nama'] as String,
      persen: (json['persen'] as num).round(),
    );
  }
}

/// Buku dari rak pengguna yang bisa dipilih saat membuat klub.
class ClubBookOption {
  const ClubBookOption({
    required this.judul,
    required this.penulis,
    required this.totalHalaman,
    required this.halamanTerakhir,
  });

  final String judul;
  final String penulis;
  final int totalHalaman;
  final int halamanTerakhir;

  int get sisaHalaman =>
      totalHalaman > halamanTerakhir ? totalHalaman - halamanTerakhir : 0;

  factory ClubBookOption.fromJson(Map<String, dynamic> json) {
    return ClubBookOption(
      judul: json['judul'] as String,
      penulis: (json['penulis'] as String?) ?? '',
      totalHalaman: json['total_halaman'] as int,
      halamanTerakhir: (json['halaman_terakhir'] as int?) ?? 0,
    );
  }
}
