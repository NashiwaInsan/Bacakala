/// Data buku (tabel `books`).
class Book {
  final String id;
  final String userId;
  final String judul;
  final String penulis;
  final int totalHalaman;
  final int halamanTerakhir;

  /// 'ingin_dibaca' | 'sedang_dibaca' | 'selesai'
  final String status;
  final String? coverUrl;
  final DateTime? createdAt;

  /// Kolom `tanggal_selesai`. Null jika kolomnya belum ada di database
  /// atau buku belum selesai. Lihat [tanggalSelesaiTampil].
  final DateTime? tanggalSelesai;

  const Book({
    required this.id,
    required this.userId,
    required this.judul,
    required this.penulis,
    required this.totalHalaman,
    required this.halamanTerakhir,
    required this.status,
    this.coverUrl,
    this.createdAt,
    this.tanggalSelesai,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final cover = json['cover_url']?.toString();
    return Book(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      judul: (json['judul'] ?? '').toString(),
      penulis: (json['penulis'] ?? '').toString(),
      totalHalaman: (json['total_halaman'] as num?)?.toInt() ?? 0,
      halamanTerakhir: (json['halaman_terakhir'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'ingin_dibaca').toString(),
      coverUrl: (cover == null || cover.trim().isEmpty) ? null : cover,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      // Aman walau kolomnya belum ada: hasilnya null.
      tanggalSelesai: DateTime.tryParse(
        (json['tanggal_selesai'] ?? '').toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'judul': judul,
    'penulis': penulis,
    'total_halaman': totalHalaman,
    'halaman_terakhir': halamanTerakhir,
    'status': status,
    'cover_url': coverUrl,
    'created_at': createdAt?.toIso8601String(),
  };

  /// Progres baca 0..1 (aman jika total halaman 0).
  double get progres {
    if (totalHalaman <= 0) return 0;
    return (halamanTerakhir / totalHalaman).clamp(0.0, 1.0);
  }

  /// Progres dalam persen bulat, mis. 55.
  int get persen => (progres * 100).round();

  /// Tanggal yang ditampilkan untuk buku selesai: `tanggal_selesai` jika ada,
  /// kalau belum ada (kolom belum dibuat) pakai `created_at`.
  DateTime? get tanggalSelesaiTampil => tanggalSelesai ?? createdAt;
}
