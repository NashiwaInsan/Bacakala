/// Data profil pengguna (tabel `profiles`).
class Profile {
  final String id;
  final String nama;
  final String email;
  final int? targetTahunan;

  /// Tautan foto profil di Storage (bucket `avatars`). Null jika belum ada.
  final String? avatarUrl;

  const Profile({
    required this.id,
    required this.nama,
    required this.email,
    this.targetTahunan,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final foto = json['avatar_url']?.toString();
    return Profile(
      id: (json['id'] ?? '').toString(),
      nama: (json['nama'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      targetTahunan: (json['target_tahunan'] as num?)?.toInt(),
      avatarUrl: (foto == null || foto.trim().isEmpty) ? null : foto,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'email': email,
    'target_tahunan': targetTahunan,
    'avatar_url': avatarUrl,
  };

  /// Nama depan, mis. "Rani Ayuningtyas" -> "Rani".
  String get namaDepan {
    final bagian = nama.trim().split(RegExp(r'\s+'));
    return bagian.first;
  }
}
