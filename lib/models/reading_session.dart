class ReadingSession {
  final String id;
  final String bookId;
  final String userId;
  final int halamanAwal;
  final int halamanAkhir;
  final int durasiMenit;
  final DateTime createdAt;

  const ReadingSession({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.halamanAwal,
    required this.halamanAkhir,
    required this.durasiMenit,
    required this.createdAt,
  });

  int get jumlahHalaman => (halamanAkhir - halamanAwal).clamp(0, 999999);

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      id: (json['id'] ?? '').toString(),
      bookId: (json['book_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      halamanAwal: (json['halaman_awal'] as num?)?.toInt() ?? 0,
      halamanAkhir: (json['halaman_akhir'] as num?)?.toInt() ?? 0,
      durasiMenit: (json['durasi_menit'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}