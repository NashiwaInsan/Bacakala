/// Data profil pengguna (tabel `profiles`).
class Profile {
  final String id;
  final String nama;
  final String email;
  final int? targetTahunan;

  const Profile({
    required this.id,
    required this.nama,
    required this.email,
    this.targetTahunan,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: (json['id'] ?? '').toString(),
      nama: (json['nama'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      targetTahunan: (json['target_tahunan'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'email': email,
    'target_tahunan': targetTahunan,
  };

  /// Nama depan, mis. "Rani Ayuningtyas" -> "Rani".
  String get namaDepan {
    final bagian = nama.trim().split(RegExp(r'\s+'));
    return bagian.first;
  }
}
