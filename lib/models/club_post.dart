/// Satu baris pada tabel `club_posts`, beserta nama penulisnya.
class ClubPost {
  const ClubPost({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.namaPenulis,
    required this.isi,
    required this.createdAt,
  });

  final String id;
  final String clubId;
  final String userId;
  final String namaPenulis;
  final String isi;
  final DateTime createdAt;

  factory ClubPost.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ClubPost(
      id: json['id'].toString(),
      clubId: json['club_id'].toString(),
      userId: json['user_id'].toString(),
      namaPenulis: (profile?['nama'] as String?) ?? 'Anggota',
      isi: json['isi'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
