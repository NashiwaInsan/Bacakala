/// Jenis catatan, sesuai nilai kolom `jenis` di tabel `notes`.
enum NoteType {
  kutipan('kutipan', 'Kutipan'),
  catatan('catatan', 'Catatan pribadi');

  const NoteType(this.value, this.label);

  /// Nilai yang disimpan di database.
  final String value;

  /// Teks yang ditampilkan ke pengguna.
  final String label;

  static NoteType fromValue(String value) => NoteType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => NoteType.catatan,
      );
}

/// Satu baris pada tabel `notes`.
class Note {
  const Note({
    this.id,
    required this.bookId,
    required this.halaman,
    required this.jenis,
    required this.isi,
    this.fotoUrl,
    this.createdAt,
  });

  /// Batas panjang isi catatan (Bab 2.2.6).
  static const int maxIsiLength = 500;

  /// `null` selama catatan belum disimpan ke database.
  final String? id;
  final String bookId;
  final int halaman;
  final NoteType jenis;
  final String isi;

  /// Link publik foto halaman di Supabase Storage, `null` jika tanpa foto.
  final String? fotoUrl;
  final DateTime? createdAt;

  bool get isKutipan => jenis == NoteType.kutipan;

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'].toString(),
      bookId: json['book_id'].toString(),
      halaman: json['halaman'] as int,
      jenis: NoteType.fromValue(json['jenis'] as String),
      isi: json['isi'] as String,
      fotoUrl: json['foto_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }

  /// Kolom yang dikirim saat tambah/ubah. `id`, `user_id`, dan `created_at`
  /// sengaja tidak ikut: `id` dan `created_at` diisi database, `user_id`
  /// ditambahkan oleh NoteService dari akun yang sedang login.
  Map<String, dynamic> toJson() {
    return {
      'book_id': bookId,
      'halaman': halaman,
      'jenis': jenis.value,
      'isi': isi,
      'foto_url': fotoUrl,
    };
  }

  Note copyWith({int? halaman, NoteType? jenis, String? isi, String? fotoUrl}) {
    return Note(
      id: id,
      bookId: bookId,
      halaman: halaman ?? this.halaman,
      jenis: jenis ?? this.jenis,
      isi: isi ?? this.isi,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      createdAt: createdAt,
    );
  }
}